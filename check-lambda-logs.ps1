# PowerShell script to check Lambda logs and DynamoDB

Write-Host "🔍 Checking SOAR Pipeline..." -ForegroundColor Cyan
Write-Host ""

# Check if we need to login
Write-Host "Testing AWS credentials..." -ForegroundColor Yellow
$testAuth = aws sts get-caller-identity 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ AWS credentials expired or not configured" -ForegroundColor Red
    Write-Host "Please login via AWS Console and copy credentials" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ AWS credentials active" -ForegroundColor Green
Write-Host ""

# 1. Check Lambda functions exist
Write-Host "1️⃣ Checking Lambda Functions..." -ForegroundColor Cyan
$lambdas = @("parser", "engine", "notify", "remediate")
foreach ($lambda in $lambdas) {
    $functionName = "casestudy2-dev-$lambda"
    Write-Host "   Checking $functionName..." -NoNewline
    $result = aws lambda get-function --function-name $functionName --region eu-central-1 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host " ✅" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
    }
}
Write-Host ""

# 2. Check recent CloudWatch Logs for Parser
Write-Host "2️⃣ Checking Parser Lambda Logs (last 5 minutes)..." -ForegroundColor Cyan
$startTime = (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("o")
$logGroup = "/aws/lambda/casestudy2-dev-parser"
Write-Host "   Log Group: $logGroup" -ForegroundColor Gray

$logStreams = aws logs describe-log-streams `
    --log-group-name $logGroup `
    --region eu-central-1 `
    --order-by LastEventTime `
    --descending `
    --max-items 1 `
    --query 'logStreams[0].logStreamName' `
    --output text 2>&1

if ($LASTEXITCODE -eq 0 -and $logStreams -ne "None") {
    Write-Host "   Latest stream: $logStreams" -ForegroundColor Gray
    
    Write-Host "   Recent events:" -ForegroundColor Yellow
    aws logs filter-log-events `
        --log-group-name $logGroup `
        --log-stream-names $logStreams `
        --region eu-central-1 `
        --max-items 10 `
        --query 'events[*].message' `
        --output text
} else {
    Write-Host "   ⚠️ No recent log streams found" -ForegroundColor Yellow
}
Write-Host ""

# 3. Check DynamoDB for recent events
Write-Host "3️⃣ Checking DynamoDB Events..." -ForegroundColor Cyan
$tableName = "casestudy2-dev-events"
Write-Host "   Table: $tableName" -ForegroundColor Gray

$items = aws dynamodb scan `
    --table-name $tableName `
    --region eu-central-1 `
    --limit 5 `
    --query 'Items[*].[event_id.S, event_name.S, source_ip.S, severity.S, status.S, timestamp.S]' `
    --output table 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host $items
} else {
    Write-Host "   ❌ Failed to query DynamoDB" -ForegroundColor Red
}
Write-Host ""

# 4. Check SQS Queue
Write-Host "4️⃣ Checking SQS Queues..." -ForegroundColor Cyan
$queues = @("parser", "engine", "notify", "remediate")
foreach ($queue in $queues) {
    $queueName = "casestudy2-dev-$queue-queue"
    Write-Host "   Checking $queueName..." -NoNewline
    
    $queueUrl = aws sqs get-queue-url --queue-name $queueName --region eu-central-1 --query 'QueueUrl' --output text 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $attrs = aws sqs get-queue-attributes `
            --queue-url $queueUrl `
            --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible `
            --region eu-central-1 `
            --output json | ConvertFrom-Json
        
        $visible = $attrs.Attributes.ApproximateNumberOfMessages
        $inFlight = $attrs.Attributes.ApproximateNumberOfMessagesNotVisible
        
        Write-Host " ✅ (Messages: $visible, In-flight: $inFlight)" -ForegroundColor Green
    } else {
        Write-Host " ❌" -ForegroundColor Red
    }
}
Write-Host ""

# 5. Check SNS Topic
Write-Host "5. Checking SNS Topic..." -ForegroundColor Cyan
$topicName = "casestudy2-dev-security-alerts"
$topics = aws sns list-topics --region eu-central-1 --query "Topics[?contains(TopicArn, ``'$topicName``')].TopicArn" --output text 2>&1

if ($LASTEXITCODE -eq 0 -and $topics) {
    Write-Host "   Topic ARN: $topics" -ForegroundColor Gray
    
    # Check subscriptions
    Write-Host "   Subscriptions:" -ForegroundColor Yellow
    aws sns list-subscriptions-by-topic --topic-arn $topics --region eu-central-1 --query 'Subscriptions[*].[Protocol, Endpoint, SubscriptionArn]' --output table
} else {
    Write-Host "   ❌ SNS Topic not found" -ForegroundColor Red
}
Write-Host ""

Write-Host "Health check complete!" -ForegroundColor Green
