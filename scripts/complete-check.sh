#!/bin/bash

echo "=== Complete Pipeline Check ==="
echo ""

echo "1. SQS Queue Status:"
aws sqs get-queue-attributes \
  --queue-url "https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-queue" \
  --attribute-names All | jq '{
    ApproximateNumberOfMessages: .Attributes.ApproximateNumberOfMessages,
    ApproximateNumberOfMessagesNotVisible: .Attributes.ApproximateNumberOfMessagesNotVisible
  }'

echo ""
echo "2. Try to receive a message from SQS:"
aws sqs receive-message \
  --queue-url "https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-queue" \
  --max-number-of-messages 1 \
  --wait-time-seconds 5

echo ""
echo "3. Recent Parser Lambda invocations:"
aws lambda get-function --function-name casestudy2-dev-parser | jq '.Configuration | {FunctionName, LastModified, State}'

echo ""
echo "4. Send a test event and wait:"
echo "Injecting test event into auth.log..."
sudo bash -c '"'"'echo "Failed password for hacker from 1.2.3.4 port 22 ssh2" >> /var/log/auth.log'"'"'
echo "Waiting 10 seconds for processing..."
sleep 10

echo ""
echo "5. Check Parser Lambda logs:"
aws logs tail /aws/lambda/casestudy2-dev-parser --since 2m --format short

echo ""
echo "6. Check recent DynamoDB events:"
aws dynamodb scan --table-name casestudy2-dev-events --limit 3 | jq -r '"'"'.Items[] | "[\(.timestamp.N)] Event: \(.event_type.S // "null") | User: \(.username.S // "null") | IP: \(.source_ip.S) | Status: \(.status.S)"'"'"'
