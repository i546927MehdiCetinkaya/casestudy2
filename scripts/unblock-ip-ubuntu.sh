#!/bin/bash
# Ubuntu IP Unblocker - Removes IPs from iptables that are no longer in DynamoDB
# Run this script periodically to clean up expired blocks

# AWS Configuration
AWS_REGION="eu-central-1"
DYNAMODB_TABLE="casestudy2-dev-blocked-ips"

# Log file
LOG_FILE="/var/log/soar-ip-blocker.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔓 Checking for IPs to unblock..."

# Get currently blocked IPs from DynamoDB
blocked_ips=$(aws dynamodb scan \
    --table-name "$DYNAMODB_TABLE" \
    --region "$AWS_REGION" \
    --query 'Items[*].ip_address.S' \
    --output text 2>/dev/null)

# Get IPs currently blocked in iptables
iptables_ips=$(sudo iptables -L INPUT -n | grep DROP | grep -oP '\d+\.\d+\.\d+\.\d+' | sort | uniq)

# Remove IPs from iptables that are not in DynamoDB
for ip in $iptables_ips; do
    if ! echo "$blocked_ips" | grep -q "$ip"; then
        sudo iptables -D INPUT -s "$ip" -j DROP 2>/dev/null
        if [ $? -eq 0 ]; then
            log "✅ IP $ip GEDEBLOKKEERD (niet meer in DynamoDB)"
            logger -t soar-blocker "Unblocked IP $ip - TTL expired"
        fi
    fi
done

log "🔓 Unblock check compleet"
