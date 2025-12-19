#!/bin/bash

# Configuration
API_ENDPOINT="https://d3h3d9waoc.execute-api.eu-central-1.amazonaws.com/dev/events"
API_KEY="REPLACE_WITH_YOUR_API_KEY"  # Run: aws apigateway get-api-key --api-key 5fk1r9nc43 --include-value --query 'value' --output text
LOG_FILE="/var/log/auth.log"
HOSTNAME=$(hostname)

echo "Starting SSH Failed Login Monitor..."
echo "Monitoring: $LOG_FILE"
echo "API Endpoint: $API_ENDPOINT"
echo ""

# Monitor auth.log for failed SSH logins
tail -Fn0 "$LOG_FILE" | while read line; do
    # Check for failed SSH login attempts
    if echo "$line" | grep -q "Failed password for"; then
        # Extract details
        TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3}')
        USERNAME=$(echo "$line" | grep -oP "Failed password for \K[^ ]+")
        SOURCE_IP=$(echo "$line" | grep -oP "from \K[0-9.]+")
        PORT=$(echo "$line" | grep -oP "port \K[0-9]+")
        
        # Convert timestamp to ISO format
        ISO_TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
        
        # Create JSON payload
        JSON_PAYLOAD=$(cat <<EOF
{
  "event_type": "failed_login",
  "timestamp": "$ISO_TIMESTAMP",
  "source_ip": "$SOURCE_IP",
  "username": "$USERNAME",
  "hostname": "$HOSTNAME",
  "service": "ssh",
  "port": $PORT,
  "auth_method": "password",
  "severity": "medium"
}
EOF
)
        
        echo "Failed login detected:"
        echo "  User: $USERNAME"
        echo "  IP: $SOURCE_IP"
        echo "  Time: $ISO_TIMESTAMP"
        
        # Send to API Gateway
        RESPONSE=$(curl -s -X POST "$API_ENDPOINT" \
            -H "x-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$JSON_PAYLOAD")
        
        if [ $? -eq 0 ]; then
            echo "  Sent to SOAR system: $RESPONSE"
        else
            echo "  Failed to send to SOAR system"
        fi
        echo ""
    fi
done
