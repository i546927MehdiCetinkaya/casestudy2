# AWS CLI Quick Reference voor SOAR System

## 🚀 Ubuntu Server - Belangrijkste Commando's

### AWS Setup
```bash
# Installeer AWS CLI en jq
sudo apt update
sudo apt install awscli jq -y

# Configureer credentials
aws configure
# Region: eu-central-1

# Test verbinding
aws sts get-caller-identity --region eu-central-1
```

### Monitoring Script
```bash
# Kopieer script
sudo cp scripts/ubuntu-monitor-failed-logins.sh /usr/local/bin/monitor-failed-logins.sh
sudo chmod +x /usr/local/bin/monitor-failed-logins.sh

# Start handmatig (voor testing)
sudo /usr/local/bin/monitor-failed-logins.sh

# Of als service
sudo systemctl start failed-login-monitor.service
sudo systemctl status failed-login-monitor.service
sudo journalctl -u failed-login-monitor.service -f
```

### Test Failed Login
```bash
# In een nieuwe terminal, probeer verkeerde login
ssh wronguser@localhost

# Of forceer met wrong password
ssh testuser@localhost
# (type verkeerd wachtwoord)
```

---

## 📊 AWS - Check SOAR System Status

### Quick Health Check
```bash
# Run complete health check
bash scripts/check-soar-health.sh

# Of handmatig check componenten:
```

### Check SQS Queues
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
REGION="eu-central-1"

# Parser Queue
aws sqs get-queue-attributes \
  --queue-url "https://sqs.${REGION}.amazonaws.com/${ACCOUNT_ID}/soar-dev-parser-queue" \
  --attribute-names ApproximateNumberOfMessages \
  --region $REGION

# Engine Queue
aws sqs get-queue-attributes \
  --queue-url "https://sqs.${REGION}.amazonaws.com/${ACCOUNT_ID}/soar-dev-engine-queue" \
  --attribute-names ApproximateNumberOfMessages \
  --region $REGION

# Notify Queue
aws sqs get-queue-attributes \
  --queue-url "https://sqs.${REGION}.amazonaws.com/${ACCOUNT_ID}/soar-dev-notify-queue" \
  --attribute-names ApproximateNumberOfMessages \
  --region $REGION
```

### Check DynamoDB Events
```bash
# Alle events (max 10)
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --max-items 10

# Alleen event IDs en status
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --query 'Items[*].[event_id.S, event_name.S, severity.S, status.S, source_ip.S]' \
  --output table

# Tel aantal events
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --select "COUNT"

# Filter op IP adres
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --filter-expression "source_ip = :ip" \
  --expression-attribute-values '{":ip":{"S":"192.168.1.100"}}' \
  --output table
```

### Check Lambda Functions
```bash
# Check if functions exist and are active
aws lambda list-functions \
  --region eu-central-1 \
  --query 'Functions[?starts_with(FunctionName, `soar-dev`)].[FunctionName, State, LastModified]' \
  --output table

# Get specific function details
aws lambda get-function \
  --function-name soar-dev-parser \
  --region eu-central-1

# Check function logs (laatste 10 regels)
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 --since 1h

# Filter errors in logs
aws logs filter-log-events \
  --log-group-name /aws/lambda/soar-dev-parser \
  --region eu-central-1 \
  --filter-pattern "ERROR" \
  --max-items 10
```

### Check EventBridge
```bash
# Check rule status
aws events describe-rule \
  --name soar-dev-security-events \
  --region eu-central-1

# List all rules
aws events list-rules \
  --region eu-central-1 \
  --name-prefix soar

# Check targets for rule
aws events list-targets-by-rule \
  --rule soar-dev-security-events \
  --region eu-central-1
```

---

## 🧪 Testing

### Send Test Event
```bash
# Run complete test
bash scripts/test-soar-system.sh

# Of handmatig test event versturen:
aws events put-events \
  --entries file://test-ubuntu-event.json \
  --region eu-central-1
```

### Manual Test Event (inline)
```bash
aws events put-events \
  --entries '[
    {
      "Source": "custom.security",
      "DetailType": "Failed Login Attempt",
      "Detail": "{\"eventType\":\"failed_login\",\"sourceIP\":\"192.168.1.100\",\"username\":\"testuser\",\"timestamp\":\"2025-10-23T14:30:00Z\",\"hostname\":\"test-server\",\"description\":\"Test failed login\"}",
      "EventBusName": "default"
    }
  ]' \
  --region eu-central-1
```

### Verify Event Processing
```bash
# Wait 10 seconds, then check:

# 1. Check Parser processed it
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 --since 5m

# 2. Check in DynamoDB
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --max-items 5 \
  --query 'Items[*].[event_id.S, event_name.S, status.S]' \
  --output table

# 3. Check Engine processed it
aws logs tail /aws/lambda/soar-dev-engine --region eu-central-1 --since 5m

# 4. Check if notification was sent (for HIGH severity)
aws logs tail /aws/lambda/soar-dev-notify --region eu-central-1 --since 5m
```

---

## 🔍 Troubleshooting

### Check Permissions
```bash
# Check your identity
aws sts get-caller-identity --region eu-central-1

# Check if you can access EventBridge
aws events list-event-buses --region eu-central-1

# Check if you can access SQS
aws sqs list-queues --region eu-central-1
```

### Clear Dead Letter Queues (if needed)
```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Purge parser DLQ
aws sqs purge-queue \
  --queue-url "https://sqs.eu-central-1.amazonaws.com/${ACCOUNT_ID}/soar-dev-parser-dlq" \
  --region eu-central-1
```

### Force Lambda Invocation (manual test)
```bash
# Test Parser Lambda directly
aws lambda invoke \
  --function-name soar-dev-parser \
  --payload file://test-ubuntu-event.json \
  --region eu-central-1 \
  response.json

# Check response
cat response.json
```

### View Full Lambda Logs
```bash
# Stream logs live
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 --follow

# Get logs from last hour
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 --since 1h

# Get logs from specific time
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 \
  --since "2025-10-23T14:00:00" \
  --until "2025-10-23T15:00:00"
```

---

## 📧 SNS Notifications

### Check SNS Topic
```bash
# List topics
aws sns list-topics --region eu-central-1

# List subscriptions
aws sns list-subscriptions --region eu-central-1

# Check if you're subscribed
aws sns list-subscriptions-by-topic \
  --topic-arn arn:aws:sns:eu-central-1:ACCOUNT_ID:soar-dev-security-alerts \
  --region eu-central-1
```

### Test SNS Manually
```bash
aws sns publish \
  --topic-arn arn:aws:sns:eu-central-1:ACCOUNT_ID:soar-dev-security-alerts \
  --subject "Test Alert" \
  --message "This is a test notification from SOAR" \
  --region eu-central-1
```

---

## 🎯 Most Used Commands (Favorites)

```bash
# Quick system health check
bash scripts/check-soar-health.sh

# Send test event
bash scripts/test-soar-system.sh

# Watch recent events
watch -n 5 'aws dynamodb scan --table-name soar-dev-events --region eu-central-1 --max-items 5 --query "Items[*].[event_id.S, event_name.S, status.S]" --output table'

# Follow parser logs
aws logs tail /aws/lambda/soar-dev-parser --region eu-central-1 --follow

# Count events in DynamoDB
aws dynamodb scan --table-name soar-dev-events --region eu-central-1 --select COUNT

# Check all queue depths
for q in parser engine remediate notify; do echo "=== $q ===" && aws sqs get-queue-attributes --queue-url "https://sqs.eu-central-1.amazonaws.com/$(aws sts get-caller-identity --query Account --output text)/soar-dev-${q}-queue" --attribute-names ApproximateNumberOfMessages --region eu-central-1 --query 'Attributes.ApproximateNumberOfMessages'; done
```

---

## 🛠️ Maintenance

### Update Lambda Function Code
```bash
# Zip new code
cd lambda/parser
zip -r parser.zip .

# Update function
aws lambda update-function-code \
  --function-name soar-dev-parser \
  --zip-file fileb://parser.zip \
  --region eu-central-1
```

### Enable/Disable EventBridge Rule
```bash
# Disable (stop receiving events)
aws events disable-rule \
  --name soar-dev-security-events \
  --region eu-central-1

# Enable
aws events enable-rule \
  --name soar-dev-security-events \
  --region eu-central-1
```

---

## 💾 Backup & Export

### Export DynamoDB Events
```bash
# Export to JSON
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 > dynamodb_backup_$(date +%Y%m%d).json

# Export specific fields to CSV-like format
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --query 'Items[*].[event_id.S, timestamp.N, event_name.S, severity.S, source_ip.S]' \
  --output text > events_$(date +%Y%m%d).txt
```
