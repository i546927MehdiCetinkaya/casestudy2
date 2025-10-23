#!/usr/bin/env pwsh
# Test the complete pipeline flow

Write-Host "=== Testing Complete Pipeline Flow ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check SQS Queue Status
Write-Host "1. Checking SQS Queue Status..." -ForegroundColor Yellow
$queueUrl = "https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-queue"
$queueStats = aws sqs get-queue-attributes --queue-url $queueUrl --attribute-names ApproximateNumberOfMessages,ApproximateNumberOfMessagesNotVisible --query 'Attributes' --output json | ConvertFrom-Json

Write-Host "   - Messages in queue: $($queueStats.ApproximateNumberOfMessages)" -ForegroundColor White
Write-Host "   - Messages in flight: $($queueStats.ApproximateNumberOfMessagesNotVisible)" -ForegroundColor White
Write-Host ""

# Step 2: Send a test event from Ubuntu
Write-Host "2. Sending test event from Ubuntu..." -ForegroundColor Yellow
Write-Host "   Run this on Ubuntu server:" -ForegroundColor Cyan
Write-Host "   sudo bash -c 'echo `"Failed password for testuser from 192.168.1.100 port 22 ssh2`" >> /var/log/auth.log'" -ForegroundColor Green
Write-Host ""
Write-Host "   Wait 5-10 seconds for the event to be processed..." -ForegroundColor Cyan
Write-Host ""

# Step 3: Check Parser Lambda logs
Write-Host "3. To check Parser Lambda logs:" -ForegroundColor Yellow
Write-Host "   aws logs tail /aws/lambda/casestudy2-dev-parser --follow --since 5m" -ForegroundColor Green
Write-Host ""

# Step 4: Check DynamoDB
Write-Host "4. To check DynamoDB for new events:" -ForegroundColor Yellow
Write-Host "   aws dynamodb scan --table-name casestudy2-dev-events --limit 5" -ForegroundColor Green
Write-Host ""

# Step 5: Check email
Write-Host "5. Check email inbox (mehdicetinkaya6132@gmail.com) for security alert" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== Pipeline Test Complete ===" -ForegroundColor Cyan
