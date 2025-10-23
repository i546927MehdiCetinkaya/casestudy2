#!/bin/bash
# Test SOAR System - Send test failed login event
# Dit script test of de hele pipeline werkt

AWS_REGION="eu-central-1"
EVENT_BUS="default"
EVENT_SOURCE="custom.security"
EVENT_DETAIL_TYPE="Failed Login Attempt"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         TEST SOAR FAILED LOGIN PIPELINE                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Generate test event
TEST_IP="203.0.113.42"  # TEST-NET-3 IP range (safe for testing)
TEST_USER="hackertest"
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
HOSTNAME=$(hostname)

echo "📋 Test Event Details:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Source IP:   $TEST_IP"
echo "Username:    $TEST_USER"
echo "Timestamp:   $TIMESTAMP"
echo "Hostname:    $HOSTNAME"
echo "Severity:    HIGH (multiple attempts simulation)"
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Step 1: Sending Test Event to EventBridge"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Create EventBridge event
event_json=$(cat <<EOF
[
  {
    "Source": "$EVENT_SOURCE",
    "DetailType": "$EVENT_DETAIL_TYPE",
    "Detail": "{\"eventType\":\"failed_login\",\"sourceIP\":\"$TEST_IP\",\"username\":\"$TEST_USER\",\"timestamp\":\"$TIMESTAMP\",\"hostname\":\"$HOSTNAME\",\"description\":\"TEST: Failed SSH login attempt from $TEST_IP for user $TEST_USER\",\"severity\":\"HIGH\"}",
    "EventBusName": "$EVENT_BUS"
  }
]
EOF
)

# Send to EventBridge
echo "Sending event..."
result=$(aws events put-events \
  --entries "$event_json" \
  --region "$AWS_REGION" 2>&1)

if [ $? -eq 0 ]; then
    echo "✅ Event sent successfully to EventBridge!"
    echo "$result"
else
    echo "❌ Failed to send event!"
    echo "$result"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⏳ Step 2: Waiting for processing (15 seconds)..."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
sleep 15

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Step 3: Checking SQS Queues"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)

queues=("parser" "engine" "remediate" "notify")
for queue in "${queues[@]}"; do
    queue_url="https://sqs.${AWS_REGION}.amazonaws.com/${ACCOUNT_ID}/soar-dev-${queue}-queue"
    
    messages=$(aws sqs get-queue-attributes \
        --queue-url "$queue_url" \
        --attribute-names ApproximateNumberOfMessages \
        --region $AWS_REGION \
        --query 'Attributes.ApproximateNumberOfMessages' \
        --output text 2>/dev/null)
    
    echo "Queue: soar-dev-${queue}-queue - Messages: $messages"
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🗄️  Step 4: Checking DynamoDB for Event"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo "Searching for events with IP $TEST_IP..."
aws dynamodb scan \
    --table-name "soar-dev-events" \
    --region $AWS_REGION \
    --filter-expression "source_ip = :ip" \
    --expression-attribute-values "{\":ip\":{\"S\":\"$TEST_IP\"}}" \
    --query 'Items[*].[event_id.S, event_name.S, severity.S, status.S, source_ip.S]' \
    --output table

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📝 Step 5: Recent Lambda Execution Logs"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for func in "parser" "engine" "notify"; do
    echo ""
    echo "Logs for /aws/lambda/soar-dev-${func}:"
    aws logs tail "/aws/lambda/soar-dev-${func}" \
        --region $AWS_REGION \
        --since 5m \
        --format short 2>/dev/null | tail -10
done

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    TEST COMPLETE                          ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "✅ Expected Results:"
echo "   1. Event in DynamoDB with status 'analyzed' or 'remediated'"
echo "   2. Parser Lambda processed event"
echo "   3. Engine Lambda analyzed event"
echo "   4. Notify Lambda sent SNS notification (check email/SNS)"
echo ""
echo "💡 To see full details of an event, use:"
echo "   aws dynamodb get-item --table-name soar-dev-events \\"
echo "     --key '{\"event_id\":{\"S\":\"EVENT_ID_HERE\"},\"timestamp\":{\"N\":\"TIMESTAMP_HERE\"}}' \\"
echo "     --region $AWS_REGION"
echo ""
