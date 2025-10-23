#!/bin/bash
# AWS SOAR System Check Script
# Gebruik dit script om je SOAR systeem te testen en checken

AWS_REGION="eu-central-1"

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         AWS SOAR SYSTEM HEALTH CHECK                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to check command
check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ SUCCESS${NC}"
    else
        echo -e "${RED}❌ FAILED${NC}"
    fi
}

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  AWS Credentials Check"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -n "Testing AWS credentials... "
aws sts get-caller-identity --region $AWS_REGION > /dev/null 2>&1
check_command

if [ $? -eq 0 ]; then
    echo "Account:"
    aws sts get-caller-identity --region $AWS_REGION --output table
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  SQS Queues Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $AWS_REGION)

queues=("parser" "engine" "remediate" "notify")
for queue in "${queues[@]}"; do
    echo -n "Checking soar-dev-${queue}-queue... "
    queue_url="https://sqs.${AWS_REGION}.amazonaws.com/${ACCOUNT_ID}/soar-dev-${queue}-queue"
    
    messages=$(aws sqs get-queue-attributes \
        --queue-url "$queue_url" \
        --attribute-names ApproximateNumberOfMessages \
        --region $AWS_REGION \
        --query 'Attributes.ApproximateNumberOfMessages' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅${NC} Messages in queue: $messages"
    else
        echo -e "${RED}❌ Queue not found or no access${NC}"
    fi
done
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  Lambda Functions Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

functions=("parser" "engine" "remediate" "notify")
for func in "${functions[@]}"; do
    echo -n "Checking soar-dev-${func}... "
    
    status=$(aws lambda get-function \
        --function-name "soar-dev-${func}" \
        --region $AWS_REGION \
        --query 'Configuration.State' \
        --output text 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        if [ "$status" = "Active" ]; then
            echo -e "${GREEN}✅ Active${NC}"
        else
            echo -e "${YELLOW}⚠️  $status${NC}"
        fi
    else
        echo -e "${RED}❌ Not found or no access${NC}"
    fi
done
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  DynamoDB Table Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -n "Checking soar-dev-events table... "
table_status=$(aws dynamodb describe-table \
    --table-name "soar-dev-events" \
    --region $AWS_REGION \
    --query 'Table.TableStatus' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ $table_status${NC}"
    
    # Count items
    item_count=$(aws dynamodb scan \
        --table-name "soar-dev-events" \
        --region $AWS_REGION \
        --select "COUNT" \
        --query 'Count' \
        --output text 2>/dev/null)
    
    echo "   Total events: $item_count"
else
    echo -e "${RED}❌ Not found or no access${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "5️⃣  EventBridge Rule Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo -n "Checking soar-dev-security-events rule... "
rule_state=$(aws events describe-rule \
    --name "soar-dev-security-events" \
    --region $AWS_REGION \
    --query 'State' \
    --output text 2>/dev/null)

if [ $? -eq 0 ]; then
    if [ "$rule_state" = "ENABLED" ]; then
        echo -e "${GREEN}✅ Enabled${NC}"
    else
        echo -e "${YELLOW}⚠️  $rule_state${NC}"
    fi
else
    echo -e "${RED}❌ Not found or no access${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "6️⃣  Recent Events in DynamoDB (Last 5)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

aws dynamodb scan \
    --table-name "soar-dev-events" \
    --region $AWS_REGION \
    --max-items 5 \
    --query 'Items[*].[event_id.S, event_name.S, severity.S, source_ip.S, status.S]' \
    --output table 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Could not fetch events${NC}"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  Lambda Function Logs (Recent Errors)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

for func in "${functions[@]}"; do
    echo "Checking /aws/lambda/soar-dev-${func}..."
    
    # Get recent error logs
    aws logs filter-log-events \
        --log-group-name "/aws/lambda/soar-dev-${func}" \
        --region $AWS_REGION \
        --filter-pattern "ERROR" \
        --max-items 3 \
        --query 'events[*].[timestamp, message]' \
        --output text 2>/dev/null | head -5
    
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  No log group or no errors${NC}"
    fi
    echo ""
done

echo "╔══════════════════════════════════════════════════════════╗"
echo "║                    HEALTH CHECK COMPLETE                  ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "💡 Tips:"
echo "   - Als queues messages hebben, draait het systeem"
echo "   - Check Lambda logs voor detailed errors"
echo "   - Test met: bash test-soar-system.sh"
echo ""
