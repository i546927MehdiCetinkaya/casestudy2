<?php
session_start();

// Simpele credentials
$correct_user = 'admin';
$correct_pass = 'admin123';

// Functie om failed login naar API Gateway te sturen (GEEN AWS credentials nodig!)
function send_failed_login_to_api_gateway($username, $source_ip) {
    $timestamp = gmdate('Y-m-d\TH:i:s\Z');
    $hostname = gethostname();
    
    // API Gateway configuratie
    $api_endpoint = 'https://h8u5lhq15h.execute-api.eu-central-1.amazonaws.com/dev/events';
    $api_key = 'Ur5VFlVJpR529I7dUbKYF4V4cGWeYmCw8S0tvyxs';
    
    // Create event payload (start with LOW severity, engine will escalate if needed)
    $event = [
        'eventType' => 'web_login_failed',
        'sourceIP' => $source_ip,
        'username' => $username,
        'timestamp' => $timestamp,
        'hostname' => $hostname,
        'loginType' => 'web',
        'url' => $_SERVER['REQUEST_URI'] ?? '/login.php',
        'userAgent' => $_SERVER['HTTP_USER_AGENT'] ?? 'Unknown',
        'description' => "Failed web login attempt from $source_ip for user $username",
        'severity' => 'LOW'  // Engine will escalate to HIGH after 3+ attempts
    ];
    
    // Send via cURL (geen AWS credentials nodig!)
    $ch = curl_init($api_endpoint);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($event));
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'x-api-key: ' . $api_key
    ]);
    curl_setopt($ch, CURLOPT_TIMEOUT, 2); // 2 second timeout
    
    $response = curl_exec($ch);
    $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    // Log resultaat
    if ($http_code === 200) {
        error_log("SOAR: Failed web login sent to API Gateway - User: $username, IP: $source_ip");
    } else {
        error_log("SOAR: Failed to send to API Gateway (HTTP $http_code) - User: $username, IP: $source_ip");
    }
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
        // Login FAILED - Send to API Gateway SOAR pipeline (GEEN AWS credentials nodig!)
        send_failed_login_to_api_gateway($username, $source_ip);
        
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
