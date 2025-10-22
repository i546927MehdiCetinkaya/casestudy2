#!/bin/bash
# Deep check Lambda event sources

echo "🔍 Deep Lambda Check..."
echo ""

# Check Lambda event source mappings
echo "1️⃣ Lambda Event Source Mappings:"
echo "=================================="
for lambda in parser engine notify remediate; do
    echo ""
    echo "📦 $lambda Lambda:"
    aws lambda list-event-source-mappings \
      --function-name "casestudy2-dev-$lambda" \
      --region eu-central-1 \
      --query 'EventSourceMappings[*].[UUID, EventSourceArn, State, LastProcessingResult]' \
      --output table
done

echo ""
echo "2️⃣ Check if SQS has messages stuck:"
echo "======================================"
queue_url=$(aws sqs get-queue-url --queue-name "casestudy2-dev-parser-queue" --region eu-central-1 --query 'QueueUrl' --output text)
echo "Parser Queue URL: $queue_url"
echo ""
echo "Receiving messages (if any):"
aws sqs receive-message \
  --queue-url "$queue_url" \
  --region eu-central-1 \
  --max-number-of-messages 5 \
  --wait-time-seconds 2

echo ""
echo "3️⃣ Manual Lambda invoke test:"
echo "==============================="
# Create test event
cat > /tmp/test-event.json <<'EOF'
{
  "Records": [
    {
      "messageId": "test-123",
      "body": "{\"Source\":\"custom.security\",\"DetailType\":\"Failed Login Attempt\",\"Detail\":\"{\\\"eventType\\\":\\\"failed_login\\\",\\\"sourceIP\\\":\\\"192.168.223.186\\\",\\\"username\\\":\\\"testuser\\\",\\\"timestamp\\\":\\\"2025-10-22T11:30:00Z\\\",\\\"hostname\\\":\\\"ubuntu-server-2404\\\",\\\"description\\\":\\\"Test failed SSH login attempt\\\"}\"}",
      "attributes": {
        "ApproximateReceiveCount": "1"
      }
    }
  ]
}
EOF

echo "Invoking Parser Lambda manually..."
aws lambda invoke \
  --function-name casestudy2-dev-parser \
  --region eu-central-1 \
  --payload file:///tmp/test-event.json \
  /tmp/lambda-response.json

echo ""
echo "Lambda response:"
cat /tmp/lambda-response.json
echo ""

echo ""
echo "✅ Deep check complete!"
