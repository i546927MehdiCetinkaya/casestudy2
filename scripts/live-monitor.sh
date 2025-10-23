#!/bin/bash
# Live Monitor - Follow Ubuntu Failed Login Monitor in Real-Time
# Dit script toont real-time output van het monitoring systeem

echo "╔══════════════════════════════════════════════════════════╗"
echo "║      Live Monitor - Ubuntu Failed Login Detection       ║"
echo "╚══════════════════════════════════════════════════════════╝"
echo ""
echo "📊 Dit toont real-time failed login attempts en AWS events"
echo "   Druk Ctrl+C om te stoppen"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if service is running
if systemctl is-active --quiet failed-login-monitor.service 2>/dev/null; then
    echo "✅ Monitoring service is active"
    echo "Following service logs..."
    echo ""
    sudo journalctl -u failed-login-monitor.service -f
else
    echo "⚠️  Service not running"
    echo "Following syslog for SOAR events..."
    echo ""
    sudo tail -f /var/log/syslog | grep --line-buffered "soar-monitor"
fi
