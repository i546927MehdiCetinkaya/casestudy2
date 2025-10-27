#!/bin/bash
# Ubuntu Failed Login Monitor - API Gateway Version
# Dit script monitort /var/log/auth.log en stuurt failed login events naar API Gateway
# GEEN AWS credentials nodig - alleen API key!

# API Configuration
API_ENDPOINT="https://d3h3d9waoc.execute-api.eu-central-1.amazonaws.com/dev/events"
API_KEY="TKL0OUWgGO4sR393v6JlN13IUGFpFfF48fBGu24l"

# Log file to monitor
LOG_FILE="/var/log/auth.log"

echo "🔍 Starting Ubuntu Failed Login Monitor (API Gateway)..."
echo "Monitoring: $LOG_FILE"
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Check if curl is installed
if ! command -v curl &> /dev/null; then
    echo "❌ curl niet gevonden!"
    echo "Installeer: sudo apt install curl -y"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq niet gevonden!"
    echo "Installeer: sudo apt install jq -y"
    exit 1
fi

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file niet gevonden: $LOG_FILE"
    exit 1
fi

echo "✅ curl en jq gevonden"
echo "✅ Log file gevonden"
echo "🚀 Start monitoring..."
echo ""

# Monitor log file for failed login attempts
tail -Fn0 "$LOG_FILE" | while read line; do
    # Check for failed password attempts
    if echo "$line" | grep -q "Failed password"; then
        # Extract details
        timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
        username=$(echo "$line" | grep -oP 'for \K[^ ]+' | head -1)
        source_ip=$(echo "$line" | grep -oP 'from \K[0-9.]+' | head -1)
        
        # Skip if no username or IP found
        if [ -z "$username" ] || [ -z "$source_ip" ]; then
            continue
        fi
        
        echo "🚨 Failed login detected:"
        echo "   Time: $timestamp"
        echo "   User: $username"
        echo "   IP: $source_ip"
        
        # Create JSON payload (start with LOW, engine escalates to HIGH after 3+ attempts)
        json_payload=$(cat <<EOF
{
  "eventType": "failed_login",
  "sourceIP": "$source_ip",
  "username": "$username",
  "timestamp": "$timestamp",
  "hostname": "$(hostname)",
  "description": "Failed SSH login attempt from $source_ip for user $username",
  "severity": "LOW"
}
EOF
)
        
        # Send to API Gateway
        echo "   📤 Sending to API Gateway..."
        
        response=$(curl -s -w "\n%{http_code}" \
          -X POST \
          -H "Content-Type: application/json" \
          -H "x-api-key: $API_KEY" \
          -d "$json_payload" \
          "$API_ENDPOINT" 2>&1)
        
        http_code=$(echo "$response" | tail -n1)
        body=$(echo "$response" | sed '$d')
        
        if [ "$http_code" = "200" ]; then
            echo "   ✅ Event sent successfully!"
            message_id=$(echo "$body" | jq -r '.messageId' 2>/dev/null)
            if [ -n "$message_id" ] && [ "$message_id" != "null" ]; then
                echo "   MessageId: $message_id"
            fi
            logger -t soar-monitor "Failed login event sent: user=$username ip=$source_ip"
        else
            echo "   ❌ Failed to send event (HTTP $http_code)"
            echo "   Response: $body"
            logger -t soar-monitor "Failed to send event: HTTP $http_code - $body"
        fi
        
        echo ""
    fi
done
