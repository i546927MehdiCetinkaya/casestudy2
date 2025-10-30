#!/bin/bash

# Configuration
API_ENDPOINT="https://d3h3d9waoc.execute-api.eu-central-1.amazonaws.com/dev/events"
API_KEY="REPLACE_WITH_YOUR_API_KEY"  # Run: aws apigateway get-api-key --api-key 5fk1r9nc43 --include-value --query 'value' --output text
LOG_FILE="/var/log/auth.log"
HOSTNAME=$(hostname)

echo "Starting SSH Failed Login Monitor..."
echo "Monitoring: $LOG_FILE"
echo "API Endpoint: $API_ENDPOINT"
echo "API Key: ${API_KEY:0:10}..." # Show first 10 chars only
echo ""

# Check if API_KEY is still placeholder
if [ "$API_KEY" = "REPLACE_WITH_YOUR_API_KEY" ]; then
    echo "ERROR: API_KEY not configured!"
    echo "Please edit this script and replace API_KEY with your actual key"
    echo "Run: aws apigateway get-api-key --api-key 5fk1r9nc43 --include-value --query 'value' --output text"
    exit 1
fi

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
        RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST "$API_ENDPOINT" \
            -H "x-api-key: $API_KEY" \
            -H "Content-Type: application/json" \
            -d "$JSON_PAYLOAD")
        
        HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_CODE:" | cut -d: -f2)
        BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE:/d')
        
        if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "202" ]; then
            echo "  ✓ Sent to SOAR system (HTTP $HTTP_CODE)"
            echo "  Response: $BODY"
        else
            echo "  ✗ Failed to send (HTTP $HTTP_CODE)"
            echo "  Response: $BODY"
            echo "  Check: API_KEY=$API_KEY"
            echo "  Endpoint: $API_ENDPOINT"
        fi
        echo ""
    fi
done
