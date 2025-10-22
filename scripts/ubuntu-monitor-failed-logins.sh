#!/bin/bash
# send-failed-login-to-aws.sh
# Monitor auth.log en stuur failed logins naar AWS EventBridge

AWS_REGION="eu-central-1"
EVENT_BUS="default"
SOURCE="fontys-netlab"

# Parse failed login uit auth.log
tail -fn0 /var/log/auth.log | while read line; do
    if echo "$line" | grep -q "Failed password"; then
        # Extract details
        TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3}')
        USERNAME=$(echo "$line" | grep -oP "for \K\w+")
        SOURCE_IP=$(echo "$line" | grep -oP "from \K[0-9.]+")
        
        # Create JSON event
        EVENT_JSON=$(cat <<EOF
{
    "Source": "$SOURCE",
    "DetailType": "Security Event",
    "Detail": "{
        \"eventType\": \"failed_login\",
        \"timestamp\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",
        \"sourceIP\": \"$SOURCE_IP\",
        \"username\": \"$USERNAME\",
        \"service\": \"SSH\",
        \"severity\": \"HIGH\",
        \"source\": \"fontys-netlab\",
        \"description\": \"Failed SSH login attempt from $SOURCE_IP for user $USERNAME\"
    }"
}
EOF
)
        
        # Send to EventBridge
        aws events put-events \
            --entries "$EVENT_JSON" \
            --region $AWS_REGION
        
        echo "[$(date)] Sent failed login event: $USERNAME from $SOURCE_IP"
    fi
done
