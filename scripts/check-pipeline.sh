#!/bin/bash
# Check SOAR Pipeline on Ubuntu

echo "🔍 Checking SOAR Pipeline..."
echo ""

# 1. Check recent events in DynamoDB
echo "1️⃣ Recent DynamoDB Events (last 10):"
echo "======================================"
aws dynamodb scan \
  --table-name casestudy2-dev-events \
  --region eu-central-1 \
  --limit 10 \
  --query 'Items[*].[event_name.S, source_ip.S, severity.S, status.S, timestamp.S]' \
  --output table

echo ""

# 2. Check Parser Lambda logs (last 5 minutes)
echo "2️⃣ Parser Lambda Logs (last 5 min):"
echo "====================================="
aws logs tail /aws/lambda/casestudy2-dev-parser \
  --region eu-central-1 \
  --since 5m \
  --format short

echo ""

# 3. Check SQS Queue depths
echo "3️⃣ SQS Queue Status:"
echo "====================="
for queue in parser engine notify remediate; do
    queue_url=$(aws sqs get-queue-url --queue-name "casestudy2-dev-${queue}-queue" --region eu-central-1 --query 'QueueUrl' --output text 2>/dev/null)
    if [ $? -eq 0 ]; then
        messages=$(aws sqs get-queue-attributes --queue-url "$queue_url" --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible --region eu-central-1 --query 'Attributes.ApproximateNumberOfMessages' --output text)
        inflight=$(aws sqs get-queue-attributes --queue-url "$queue_url" --attribute-names ApproximateNumberOfMessagesNotVisible --region eu-central-1 --query 'Attributes.ApproximateNumberOfMessagesNotVisible' --output text)
        echo "$queue-queue: $messages visible, $inflight in-flight"
    fi
done

echo ""

# 4. Check EventBridge rule
echo "4️⃣ EventBridge Rule Status:"
echo "============================="
aws events describe-rule --name "casestudy2-dev-security-events" --region eu-central-1 --query '[Name, State]' --output table

echo ""

# 5. Test EventBridge directly
echo "5️⃣ Testing EventBridge (sending test event):"
echo "=============================================="
aws events put-events \
  --entries '[{"Source":"custom.security","DetailType":"Test Event","Detail":"{\"test\":\"true\"}"}]' \
  --region eu-central-1

echo ""
echo "✅ Pipeline check complete!"
