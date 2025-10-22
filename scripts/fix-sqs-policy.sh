#!/bin/bash
# Manually fix SQS queue policy

echo "🔧 Manually updating SQS queue policy..."
echo ""

QUEUE_URL="https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-queue"
RULE_ARN="arn:aws:events:eu-central-1:920120424621:rule/casestudy2-dev-security-events"

echo "Queue URL: $QUEUE_URL"
echo "Rule ARN: $RULE_ARN"
echo ""

# Create policy JSON
cat > /tmp/sqs-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowEventBridgeToSendMessage",
      "Effect": "Allow",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Action": "sqs:SendMessage",
      "Resource": "arn:aws:sqs:eu-central-1:920120424621:casestudy2-dev-parser-queue",
      "Condition": {
        "ArnEquals": {
          "aws:SourceArn": "$RULE_ARN"
        }
      }
    }
  ]
}
EOF

echo "Setting queue policy..."
POLICY=$(cat /tmp/sqs-policy.json)
aws sqs set-queue-attributes \
  --queue-url "$QUEUE_URL" \
  --attributes Policy="$POLICY" \
  --region eu-central-1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Policy updated successfully!"
    echo ""
    echo "Verifying..."
    aws sqs get-queue-attributes \
      --queue-url "$QUEUE_URL" \
      --attribute-names Policy \
      --region eu-central-1 \
      --query 'Attributes.Policy' \
      --output text
else
    echo ""
    echo "❌ Failed to update policy"
fi
