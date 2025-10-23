<?php
session_start();

// Simpele credentials
$correct_user = 'admin';
$correct_pass = 'admin123';

// Functie om failed login naar EventBridge te sturen
function send_failed_login_to_eventbridge($username, $source_ip) {
    $timestamp = gmdate('Y-m-d\TH:i:s\Z');
    $hostname = gethostname();
    
    // Create EventBridge event JSON
    $event = [
        [
            'Source' => 'custom.security',
            'DetailType' => 'Failed Login Attempt',
            'Detail' => json_encode([
                'eventType' => 'web_login_failed',
                'sourceIP' => $source_ip,
                'username' => $username,
                'timestamp' => $timestamp,
                'hostname' => $hostname,
                'loginType' => 'web',
                'url' => $_SERVER['REQUEST_URI'] ?? '/login.php',
                'userAgent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown',
                'description' => "Failed web login attempt from $source_ip for user $username"
            ]),
            'EventBusName' => 'default'
        ]
    ];
    
    $event_json = json_encode($event);
    
    // Escape voor shell
    $event_escaped = escapeshellarg($event_json);
    
    // Send via AWS CLI (asynchroon in background)
    $cmd = "aws events put-events --entries $event_escaped --region eu-central-1 2>&1 &";
    exec($cmd);
    
    // Log ook lokaal
    error_log("SOAR: Failed web login - User: $username, IP: $source_ip");
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = $_POST['username'] ?? '';
    $password = $_POST['password'] ?? '';
    
    // Get source IP (ook achter proxy/load balancer)
    $source_ip = $_SERVER['HTTP_X_FORWARDED_FOR'] ?? $_SERVER['REMOTE_ADDR'] ?? 'Unknown';
    if (strpos($source_ip, ',') !== false) {
        $source_ip = trim(explode(',', $source_ip)[0]);
    }

    if ($username === $correct_user && $password === $correct_pass) {
        // Login SUCCESS
        $_SESSION['logged_in'] = true;
        $_SESSION['username'] = $username;
        $_SESSION['login_time'] = time();
        
        // Log successful login
        error_log("SOAR: Successful web login - User: $username, IP: $source_ip");
        
        header('Location: dashboard.php');
        exit();
    } else {
        // Login FAILED - Send to EventBridge SOAR pipeline
        send_failed_login_to_eventbridge($username, $source_ip);
        
        http_response_code(401);
        echo '<!DOCTYPE html>
<html>
<head>
    <title>Login Failed</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; margin-top: 50px; }
        .error { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <div class="error">
        <h2>🚨 Login Failed</h2>
        <p>Invalid credentials. This incident has been logged and security team has been notified.</p>
        <p><a href="index.html">← Return to login</a></p>
    </div>
</body>
</html>';
        exit();
    }
}
?>
