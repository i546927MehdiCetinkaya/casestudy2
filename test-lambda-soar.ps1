# Lambda SOAR Test Script
# Run dit in AWS CloudShell of met AWS CLI credentials

Write-Host "🧪 Testing Lambda SOAR Pipeline..." -ForegroundColor Cyan

# Test 1: Parser Lambda
Write-Host "`n1️⃣ Testing Parser Lambda..." -ForegroundColor Yellow

$parserPayload = @{
    Records = @(
        @{
            messageId = "test-123"
            body = '{"eventType":"failed_login","timestamp":"2025-10-22T08:15:00Z","sourceIP":"192.168.154.50","username":"admin","attemptCount":5,"service":"SSH","severity":"HIGH"}'
        }
    )
} | ConvertTo-Json -Depth 5

Write-Host "Invoking casestudy2-dev-parser..."
aws lambda invoke `
    --function-name casestudy2-dev-parser `
    --payload $parserPayload `
    --region eu-central-1 `
    parser-response.json

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Parser Lambda executed" -ForegroundColor Green
    Get-Content parser-response.json | ConvertFrom-Json | ConvertTo-Json -Depth 5
} else {
    Write-Host "❌ Parser Lambda failed" -ForegroundColor Red
}

# Test 2: Check CloudWatch Logs
Write-Host "`n2️⃣ Checking CloudWatch Logs..." -ForegroundColor Yellow

$logGroups = @(
    "/aws/lambda/casestudy2-dev-parser",
    "/aws/lambda/casestudy2-dev-engine",
    "/aws/lambda/casestudy2-dev-notify",
    "/aws/lambda/casestudy2-dev-remediate"
)

foreach ($logGroup in $logGroups) {
    Write-Host "`nLog Group: $logGroup" -ForegroundColor Cyan
    
    # Get latest log stream
    $streams = aws logs describe-log-streams `
        --log-group-name $logGroup `
        --order-by LastEventTime `
        --descending `
        --max-items 1 `
        --region eu-central-1 | ConvertFrom-Json
    
    if ($streams.logStreams) {
        $streamName = $streams.logStreams[0].logStreamName
        Write-Host "Latest stream: $streamName"
        
        # Get recent logs
        aws logs get-log-events `
            --log-group-name $logGroup `
            --log-stream-name $streamName `
            --limit 10 `
            --region eu-central-1 `
            --query 'events[*].[timestamp,message]' `
            --output text
    } else {
        Write-Host "No log streams found" -ForegroundColor Gray
    }
}

# Test 3: Check DynamoDB
Write-Host "`n3️⃣ Checking DynamoDB Events Table..." -ForegroundColor Yellow

aws dynamodb scan `
    --table-name casestudy2-dev-events `
    --limit 5 `
    --region eu-central-1 `
    --query 'Items[*]' `
    --output json | ConvertFrom-Json | ConvertTo-Json -Depth 5

# Test 4: Check SQS Queues
Write-Host "`n4️⃣ Checking SQS Queues..." -ForegroundColor Yellow

$queues = aws sqs list-queues `
    --queue-name-prefix casestudy2-dev `
    --region eu-central-1 | ConvertFrom-Json

foreach ($queueUrl in $queues.QueueUrls) {
    Write-Host "`nQueue: $queueUrl" -ForegroundColor Cyan
    
    aws sqs get-queue-attributes `
        --queue-url $queueUrl `
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible `
        --region eu-central-1 `
        --query 'Attributes' `
        --output json | ConvertFrom-Json | ConvertTo-Json
}

Write-Host "`n✅ Testing Complete!" -ForegroundColor Green
Write-Host "`n📊 View detailed logs in AWS Console:" -ForegroundColor Cyan
Write-Host "https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/%2Faws%2Flambda%2Fcasestudy2-dev-parser" -ForegroundColor Blue
