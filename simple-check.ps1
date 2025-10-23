# Simple SOAR Pipeline Check
Write-Host "Checking SOAR Pipeline..." -ForegroundColor Cyan
Write-Host ""

# Check DynamoDB
Write-Host "Checking DynamoDB Events..." -ForegroundColor Yellow
aws dynamodb scan `
    --table-name casestudy2-dev-events `
    --region eu-central-1 `
    --limit 5 `
    --query 'Items[*].[event_name.S, source_ip.S, severity.S, status.S]' `
    --output table

Write-Host ""

# Check Parser Lambda logs
Write-Host "Checking Parser Lambda Logs (last 20 events)..." -ForegroundColor Yellow
aws logs tail /aws/lambda/casestudy2-dev-parser --region eu-central-1 --since 5m --format short

Write-Host ""

# Check SQS Queues
Write-Host "Checking SQS Queue Messages..." -ForegroundColor Yellow
$queues = @("parser", "engine", "notify", "remediate")
foreach ($queue in $queues) {
    $queueUrl = aws sqs get-queue-url --queue-name "casestudy2-dev-$queue-queue" --region eu-central-1 --query 'QueueUrl' --output text
    $attrs = aws sqs get-queue-attributes --queue-url $queueUrl --attribute-names ApproximateNumberOfMessages --region eu-central-1 --output json | ConvertFrom-Json
    Write-Host "$queue queue: $($attrs.Attributes.ApproximateNumberOfMessages) messages"
}
