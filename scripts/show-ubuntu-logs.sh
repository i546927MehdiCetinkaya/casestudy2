#!/bin/bash
# Show Ubuntu Monitor Logs
# Dit script toont alle relevante logs van het monitoring systeem

echo "╔══════════════════════════════════════════════════════════╗"
echo "║         Ubuntu Failed Login Monitor - Logs              ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}1️⃣  System Auth Log (Failed Login Attempts)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Recent failed password attempts (last 20):"
echo ""
sudo grep "Failed password" /var/log/auth.log | tail -20

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}2️⃣  SOAR Monitor Logs (syslog)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "Recent SOAR monitor events:"
echo ""
sudo grep "soar-monitor" /var/log/syslog | tail -20

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}3️⃣  Systemd Service Logs (if running as service)${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if systemctl is-active --quiet failed-login-monitor.service 2>/dev/null; then
    echo -e "${GREEN}✅ Service is running${NC}"
    echo ""
    echo "Recent service logs (last 50 lines):"
    sudo journalctl -u failed-login-monitor.service -n 50 --no-pager
else
    echo -e "${YELLOW}⚠️  Service not running or not configured${NC}"
    echo "Run manually: sudo /usr/local/bin/monitor-failed-logins.sh"
fi

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}4️⃣  Summary Statistics${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

total_failed=$(sudo grep -c "Failed password" /var/log/auth.log)
echo "Total failed login attempts today: $total_failed"

sent_events=$(sudo grep -c "Failed login event sent" /var/log/syslog 2>/dev/null || echo "0")
echo "Events sent to AWS: $sent_events"

failed_sends=$(sudo grep -c "Failed to send event" /var/log/syslog 2>/dev/null || echo "0")
echo "Failed to send: $failed_sends"

echo ""
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${YELLOW}5️⃣  Top IPs with Failed Attempts${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

sudo grep "Failed password" /var/log/auth.log | \
    grep -oP 'from \K[0-9.]+' | \
    sort | uniq -c | sort -rn | head -10

echo ""
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}Logs complete!${NC}"
echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
