#!/bin/bash
# Check Ubuntu Server Type en AWS Access
# Bepaalt de beste manier om AWS credentials te configureren

echo "╔══════════════════════════════════════════════════════════╗"
echo "║     Ubuntu Server Type Check voor AWS Credentials       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}1️⃣  Checking if this is an EC2 instance...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Try to get EC2 metadata
INSTANCE_ID=$(curl -s --connect-timeout 3 http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null)

if [ -n "$INSTANCE_ID" ]; then
    echo -e "${GREEN}✅ This IS an EC2 instance!${NC}"
    echo -e "   Instance ID: $INSTANCE_ID"
    
    # Get more EC2 info
    REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region 2>/dev/null)
    AZ=$(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null)
    INSTANCE_TYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type 2>/dev/null)
    
    echo -e "   Region: ${BLUE}$REGION${NC}"
    echo -e "   AZ: ${BLUE}$AZ${NC}"
    echo -e "   Type: ${BLUE}$INSTANCE_TYPE${NC}"
    
    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✅ RECOMMENDED: Use IAM Role (Instance Profile)${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Steps:"
    echo "  1. Create IAM Role in AWS Console"
    echo "  2. Attach policy: events:PutEvents"
    echo "  3. Attach role to this EC2 instance"
    echo "  4. Remove credentials file: rm ~/.aws/credentials"
    echo "  5. AWS CLI will use instance role automatically!"
    echo ""
    echo -e "${BLUE}See: FIX-TOKEN-WITH-IAM-ROLE.md - OPTIE A${NC}"
    
    IS_EC2=true
else
    echo -e "${YELLOW}⚠️  This is NOT an EC2 instance${NC}"
    echo -e "   (External VM, VMware, VirtualBox, or on-premise)"
    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  You need IAM User Access Keys or SSO${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "Options:"
    echo "  1. Ask school admin to create IAM User for you"
    echo "  2. Use SSO with auto-refresh (manual work)"
    echo ""
    echo -e "${BLUE}See: FIX-TOKEN-WITH-IAM-ROLE.md - OPTIE B or C${NC}"
    
    IS_EC2=false
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}2️⃣  Checking current AWS credentials...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not installed!${NC}"
    echo "Install: sudo apt install awscli -y"
    exit 1
fi

echo "Testing current credentials..."
IDENTITY=$(aws sts get-caller-identity --region eu-central-1 2>&1)

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ AWS credentials work!${NC}"
    echo ""
    echo "$IDENTITY" | jq '.' 2>/dev/null || echo "$IDENTITY"
    
    # Check if using instance role
    if echo "$IDENTITY" | grep -q "assumed-role"; then
        echo ""
        if [ "$IS_EC2" = true ]; then
            echo -e "${GREEN}✅ Using EC2 Instance Role - Perfect!${NC}"
        else
            echo -e "${BLUE}ℹ️  Using assumed role (SSO?)${NC}"
        fi
    else
        echo ""
        echo -e "${BLUE}ℹ️  Using IAM User or other credentials${NC}"
    fi
else
    echo -e "${RED}❌ AWS credentials NOT working!${NC}"
    echo ""
    echo "Error:"
    echo "$IDENTITY"
    echo ""
    
    if echo "$IDENTITY" | grep -q "ExpiredToken"; then
        echo -e "${RED}🔴 Token is EXPIRED!${NC}"
        echo ""
        if [ "$IS_EC2" = true ]; then
            echo "Solution: Attach IAM Role to EC2 instance"
        else
            echo "Solution: Refresh SSO or get IAM User"
        fi
    fi
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}3️⃣  Checking EventBridge access...${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

EB_TEST=$(aws events put-events \
  --entries '[{
    "Source": "custom.security.test",
    "DetailType": "Connection Test",
    "Detail": "{\"test\":\"true\"}",
    "EventBusName": "default"
  }]' \
  --region eu-central-1 2>&1)

if [ $? -eq 0 ]; then
    if echo "$EB_TEST" | grep -q '"FailedEntryCount": 0'; then
        echo -e "${GREEN}✅ EventBridge access works!${NC}"
        echo "$EB_TEST"
    else
        echo -e "${YELLOW}⚠️  EventBridge returned errors${NC}"
        echo "$EB_TEST"
    fi
else
    echo -e "${RED}❌ EventBridge access failed!${NC}"
    echo "$EB_TEST"
    echo ""
    echo "Possible causes:"
    echo "  - No events:PutEvents permission"
    echo "  - Token expired"
    echo "  - No credentials configured"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                      SUMMARY                             ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

if [ "$IS_EC2" = true ]; then
    echo -e "${GREEN}✅ EC2 Instance detected${NC}"
    echo ""
    echo "RECOMMENDED SETUP:"
    echo "  1. Create IAM Role with events:PutEvents policy"
    echo "  2. Attach role to EC2 instance"
    echo "  3. Remove ~/.aws/credentials"
    echo "  4. Keep only ~/.aws/config with region"
    echo ""
    echo -e "${BLUE}📖 Guide: FIX-TOKEN-WITH-IAM-ROLE.md (OPTIE A)${NC}"
else
    echo -e "${YELLOW}⚠️  Non-EC2 server detected${NC}"
    echo ""
    echo "AVAILABLE OPTIONS:"
    echo "  A. Ask school for IAM User (permanent solution)"
    echo "  B. Use SSO with manual refresh (requires work)"
    echo ""
    echo -e "${BLUE}📖 Guide: FIX-TOKEN-WITH-IAM-ROLE.md (OPTIE B/C)${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
