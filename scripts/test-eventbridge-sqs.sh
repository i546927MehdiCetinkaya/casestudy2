#!/bin/bash
# Test EventBridge to SQS connection

echo "🔍 Testing EventBridge → SQS Flow..."
echo ""

# 1. Send a custom.security event
echo "1️⃣ Sending test event to EventBridge..."
echo "========================================="
result=$(aws events put-events \
  --entries '[
    {
      "Source": "custom.security",
      "DetailType": "Failed Login Attempt",
      "Detail": "{\"eventType\":\"failed_login\",\"sourceIP\":\"1.2.3.4\",\"username\":\"testuser\",\"timestamp\":\"2025-10-22T12:00:00Z\",\"description\":\"Test event\"}"
    }
  ]' \
  --region eu-central-1)

echo "$result"
event_id=$(echo "$result" | grep -o '"EventId": "[^"]*"' | cut -d'"' -f4)
echo ""
echo "✅ Event sent with ID: $event_id"
echo ""

# 2. Wait a bit for processing
echo "⏳ Waiting 5 seconds for EventBridge to process..."
sleep 5
echo ""

# 3. Check SQS queue for message
echo "2️⃣ Checking parser-queue for messages..."
echo "=========================================="
queue_url=$(aws sqs get-queue-url --queue-name "casestudy2-dev-parser-queue" --region eu-central-1 --query 'QueueUrl' --output text)

# Get queue attributes
attrs=$(aws sqs get-queue-attributes \
  --queue-url "$queue_url" \
  --attribute-names All \
  --region eu-central-1)

echo "Queue metrics:"
echo "$attrs" | grep -E "ApproximateNumberOfMessages|ApproximateNumberOfMessagesNotVisible"
echo ""

# Try to receive message
echo "3️⃣ Attempting to receive message from queue..."
echo "==============================================="
message=$(aws sqs receive-message \
  --queue-url "$queue_url" \
  --region eu-central-1 \
  --max-number-of-messages 1 \
  --wait-time-seconds 5 \
  --attribute-names All)

if [ -n "$message" ] && [ "$message" != "{}" ]; then
    echo "✅ Message received!"
    echo "$message" | jq '.'
else
    echo "❌ No message in queue!"
    echo ""
    echo "🔍 Checking EventBridge rule targets..."
    aws events list-targets-by-rule \
      --rule "casestudy2-dev-security-events" \
      --region eu-central-1
fi

echo ""
echo "✅ Test complete!"
