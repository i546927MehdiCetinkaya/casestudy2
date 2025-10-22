#!/bin/bash
# Ubuntu Failed Login Monitor voor AWS Lambda SOAR
# Dit script monitort /var/log/auth.log en stuurt failed login events naar EventBridge

# AWS Configuration
AWS_REGION="eu-central-1"
EVENT_BUS="default"
EVENT_SOURCE="custom.security"
EVENT_DETAIL_TYPE="Failed Login Attempt"
ROLE_ARN="REPLACE_WITH_ROLE_ARN"  # Wordt ingevuld na terraform apply

# Log file to monitor
LOG_FILE="/var/log/auth.log"

echo "🔍 Starting Ubuntu Failed Login Monitor..."
echo "Monitoring: $LOG_FILE"
echo "Region: $AWS_REGION"
echo "Role ARN: $ROLE_ARN"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI niet gevonden!"
    echo "Installeer: sudo apt install awscli jq"
    exit 1
fi

# Check if jq is installed
if ! command -v jq &> /dev/null; then
    echo "❌ jq niet gevonden!"
    echo "Installeer: sudo apt install jq"
    exit 1
fi

# Check if log file exists
if [ ! -f "$LOG_FILE" ]; then
    echo "❌ Log file niet gevonden: $LOG_FILE"
    exit 1
fi

echo "✅ AWS CLI en jq gevonden"
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
        
        # Create EventBridge event
        event_json=$(cat <<EOF
[
  {
    "Source": "$EVENT_SOURCE",
    "DetailType": "$EVENT_DETAIL_TYPE",
    "Detail": "{\"eventType\":\"failed_login\",\"sourceIP\":\"$source_ip\",\"username\":\"$username\",\"timestamp\":\"$timestamp\",\"hostname\":\"$(hostname)\",\"description\":\"Failed SSH login attempt from $source_ip for user $username\"}",
    "EventBusName": "$EVENT_BUS"
  }
]
EOF
)
        
        # Assume role and send to EventBridge
        echo "   📤 Sending to EventBridge via AssumeRole..."
        
        # Assume role (credentials cached for 1 hour)
        TEMP_CREDS=$(aws sts assume-role \
          --role-arn "$ROLE_ARN" \
          --role-session-name "ubuntu-monitor-$(date +%s)" \
          --duration-seconds 3600 \
          --region "$AWS_REGION" 2>&1)
        
        if [ $? -ne 0 ]; then
            echo "   ❌ Failed to assume role: $TEMP_CREDS"
            logger -t soar-monitor "Failed to assume role: $TEMP_CREDS"
            continue
        fi
        
        # Extract credentials
        export AWS_ACCESS_KEY_ID=$(echo "$TEMP_CREDS" | jq -r '.Credentials.AccessKeyId')
        export AWS_SECRET_ACCESS_KEY=$(echo "$TEMP_CREDS" | jq -r '.Credentials.SecretAccessKey')
        export AWS_SESSION_TOKEN=$(echo "$TEMP_CREDS" | jq -r '.Credentials.SessionToken')
        
        # Send to EventBridge with assumed role credentials
        result=$(aws events put-events \
          --entries "$event_json" \
          --region "$AWS_REGION" 2>&1)
        
        if [ $? -eq 0 ]; then
            echo "   ✅ Event sent successfully!"
            logger -t soar-monitor "Failed login event sent: user=$username ip=$source_ip"
        else
            echo "   ❌ Failed to send event: $result"
            logger -t soar-monitor "Failed to send event: $result"
        fi
        
        # Clear credentials
        unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
        
        echo ""
    fi
done
