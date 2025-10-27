#!/bin/bash
# Ubuntu IP Blocker - Checks DynamoDB and blocks IPs with iptables
# Run this script periodically (e.g., via cron every minute)

# AWS Configuration
AWS_REGION="eu-central-1"
DYNAMODB_TABLE="casestudy2-dev-blocked-ips"

# Log file
LOG_FILE="/var/log/soar-ip-blocker.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔍 Checking DynamoDB for blocked IPs..."

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    log "❌ AWS CLI niet gevonden! Installeer met: sudo apt install awscli -y"
    exit 1
fi

# Get all blocked IPs from DynamoDB
blocked_ips=$(aws dynamodb scan \
    --table-name "$DYNAMODB_TABLE" \
    --region "$AWS_REGION" \
    --query 'Items[*].ip_address.S' \
    --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    log "❌ Fout bij ophalen van blocked IPs uit DynamoDB"
    exit 1
fi

if [ -z "$blocked_ips" ]; then
    log "ℹ️  Geen geblokkeerde IPs gevonden in DynamoDB"
    exit 0
fi

log "📋 Gevonden geblokkeerde IPs: $blocked_ips"

# Block each IP with iptables
for ip in $blocked_ips; do
    # Check if IP is already blocked
    if sudo iptables -L INPUT -n | grep -q "$ip"; then
        log "✓ IP $ip is al geblokkeerd"
    else
        # Block the IP
        sudo iptables -I INPUT -s "$ip" -j DROP
        if [ $? -eq 0 ]; then
            log "🚫 IP $ip GEBLOKKEERD met iptables"
            logger -t soar-blocker "Blocked IP $ip via iptables"
        else
            log "❌ Fout bij blokkeren van IP $ip"
        fi
    fi
done

# Show current blocked IPs
log "📊 Huidige iptables regels:"
sudo iptables -L INPUT -n | grep DROP | tee -a "$LOG_FILE"

log "✅ IP blocker check compleet"
