#!/bin/bash
# Check SQS Queue Policy

echo "🔍 Checking SQS Queue Policy..."
echo ""

# Get queue URL
queue_url=$(aws sqs get-queue-url --queue-name "casestudy2-dev-parser-queue" --region eu-central-1 --query 'QueueUrl' --output text)
echo "Queue URL: $queue_url"
echo ""

# Get queue policy
echo "Current Queue Policy:"
echo "====================="
aws sqs get-queue-attributes \
  --queue-url "$queue_url" \
  --attribute-names Policy \
  --region eu-central-1 \
  --query 'Attributes.Policy' \
  --output text | jq '.'

echo ""
echo "EventBridge Rule ARN:"
echo "====================="
aws events describe-rule \
  --name "casestudy2-dev-security-events" \
  --region eu-central-1 \
  --query 'Arn' \
  --output text

echo ""
echo "✅ Check complete!"
