#!/bin/bash
# Quick IAM User Setup Verificatie
# Run dit nadat je IAM User hebt aangemaakt

echo "╔══════════════════════════════════════════════════════════╗"
echo "║       IAM User Credentials Setup voor SOAR Monitor      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STAP 1: Verwijder oude SSO credentials${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Wil je oude credentials verwijderen? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Backing up old credentials..."
    if [ -f ~/.aws/credentials ]; then
        cp ~/.aws/credentials ~/.aws/credentials.backup.$(date +%Y%m%d_%H%M%S)
        echo -e "${GREEN}✅ Backup gemaakt${NC}"
    fi
    
    rm -rf ~/.aws/credentials
    echo -e "${GREEN}✅ Oude credentials verwijderd${NC}"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STAP 2: Configureer nieuwe IAM User credentials${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${BLUE}Heb je al een IAM User aangemaakt met Access Keys?${NC}"
echo ""
echo "Zo niet, doe dit eerst in AWS Console:"
echo "  1. IAM → Users → Create User"
echo "  2. Username: soar-ubuntu-monitor"
echo "  3. Attach policy met: events:PutEvents permission"
echo "  4. Create Access Keys"
echo ""

read -p "Heb je de Access Keys klaar? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Maak eerst de IAM User en Access Keys aan.${NC}"
    echo "Zie FIX-AWS-TOKEN-ISSUE.md voor instructies"
    exit 1
fi

echo ""
echo -e "${GREEN}Configureer AWS CLI met je IAM User credentials:${NC}"
echo -e "${BLUE}LET OP: Vul GEEN Session Token in! Druk gewoon Enter.${NC}"
echo ""

aws configure

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STAP 3: Test credentials${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Testing AWS credentials..."
if aws sts get-caller-identity --region eu-central-1 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Credentials werken!${NC}"
    echo ""
    aws sts get-caller-identity --region eu-central-1
else
    echo -e "${RED}❌ Credentials werken niet!${NC}"
    echo "Check of je de juiste Access Key en Secret Key hebt ingevoerd."
    exit 1
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STAP 4: Test EventBridge toegang${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Testing EventBridge PutEvents permission..."
result=$(aws events put-events \
  --entries '[{
    "Source": "custom.security",
    "DetailType": "Test Event",
    "Detail": "{\"test\":\"credential_test\"}",
    "EventBusName": "default"
  }]' \
  --region eu-central-1 2>&1)

if echo "$result" | grep -q "FailedEntryCount.*0"; then
    echo -e "${GREEN}✅ EventBridge toegang werkt!${NC}"
    echo "$result"
else
    echo -e "${RED}❌ EventBridge toegang werkt niet!${NC}"
    echo "$result"
    echo ""
    echo "Mogelijke oorzaken:"
    echo "  - IAM User heeft geen events:PutEvents permission"
    echo "  - Policy is niet correct attached"
    exit 1
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}STAP 5: Test monitoring script${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ ! -f /usr/local/bin/monitor-failed-logins.sh ]; then
    echo -e "${RED}❌ Monitoring script niet gevonden!${NC}"
    echo "Kopieer eerst het script naar /usr/local/bin/monitor-failed-logins.sh"
    exit 1
fi

echo -e "${BLUE}Wil je het monitoring script testen? (dit draait totdat je Ctrl+C drukt)${NC}"
read -p "Test nu? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${GREEN}Starting monitoring script...${NC}"
    echo -e "${BLUE}In een andere terminal: ssh wronguser@localhost (met verkeerd wachtwoord)${NC}"
    echo -e "${BLUE}Druk Ctrl+C om te stoppen${NC}"
    echo ""
    sudo /usr/local/bin/monitor-failed-logins.sh
fi

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║                  SETUP COMPLETE! ✅                      ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Je credentials zijn geconfigureerd en werken!${NC}"
echo ""
echo "Volgende stappen:"
echo "  1. Setup als systemd service (zie UBUNTU-STAPPENPLAN.txt stap 8)"
echo "  2. Test met echte failed login"
echo "  3. Verificeer in AWS DynamoDB en Lambda logs"
echo ""
