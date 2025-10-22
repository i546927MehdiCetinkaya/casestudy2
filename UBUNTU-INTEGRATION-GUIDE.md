# 🔗 Ubuntu Server → AWS Lambda SOAR Integration

## Setup: Failed Login Monitoring van 192.168.154.13

### Vereisten:
- ✅ Ubuntu server: 192.168.154.13
- ✅ Site-to-Site VPN tunnel actief (al geconfigureerd!)
- ✅ AWS CLI op Ubuntu server
- ✅ IAM credentials voor EventBridge

---

## 📋 Stap 1: AWS CLI Installeren op Ubuntu

SSH naar de Ubuntu server:
```bash
ssh user@192.168.154.13
```

Installeer AWS CLI:
```bash
sudo apt update
sudo apt install -y awscli jq

# Verify installatie
aws --version
```

---

## 🔑 Stap 2: AWS Credentials Configureren

### Optie A: IAM User Credentials (Simpel)

1. **Maak IAM User in AWS Console:**
   - Ga naar: https://console.aws.amazon.com/iam/home#/users
   - Create user: `ubuntu-eventbridge-sender`
   - Attach policy: `AmazonEventBridgePutEventsAccess`
   - Create access keys
   - Copy: Access Key ID + Secret Access Key

2. **Configureer op Ubuntu:**
```bash
aws configure
# AWS Access Key ID: [PASTE]
# AWS Secret Access Key: [PASTE]
# Default region: eu-central-1
# Default output format: json
```

### Optie B: IAM Role via VPN (Advanced)

Gebruik EC2 instance profile (als Ubuntu in AWS draait).

---

## 📜 Stap 3: Monitor Script Installeren

**Download script naar Ubuntu:**
```bash
# Maak directory
sudo mkdir -p /opt/soar-monitor
cd /opt/soar-monitor

# Download script (van GitHub of manual copy)
sudo nano send-failed-login-to-aws.sh
```

**Plak deze inhoud:**
```bash
#!/bin/bash
# Monitor auth.log en stuur failed logins naar AWS EventBridge

AWS_REGION="eu-central-1"
EVENT_BUS="default"
SOURCE="fontys-netlab"

tail -fn0 /var/log/auth.log | while read line; do
    if echo "$line" | grep -q "Failed password"; then
        TIMESTAMP=$(echo "$line" | awk '{print $1, $2, $3}')
        USERNAME=$(echo "$line" | grep -oP "for \K\\w+")
        SOURCE_IP=$(echo "$line" | grep -oP "from \K[0-9.]+")
        
        EVENT_JSON=$(cat <<EOF
[{
    "Source": "$SOURCE",
    "DetailType": "Security Event",
    "Detail": "{\\"eventType\\": \\"failed_login\\", \\"timestamp\\": \\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\\", \\"sourceIP\\": \\"$SOURCE_IP\\", \\"username\\": \\"$USERNAME\\", \\"service\\": \\"SSH\\", \\"severity\\": \\"HIGH\\", \\"source\\": \\"fontys-netlab\\", \\"description\\": \\"Failed SSH login from $SOURCE_IP for user $USERNAME\\"}"
}]
EOF
)
        
        aws events put-events \
            --entries "$EVENT_JSON" \
            --region $AWS_REGION 2>&1 | logger -t soar-monitor
        
        echo "[$(date)] Failed login: $USERNAME from $SOURCE_IP"
    fi
done
```

**Maak executable:**
```bash
sudo chmod +x /opt/soar-monitor/send-failed-login-to-aws.sh
```

---

## 🚀 Stap 4: Systemd Service Maken

**Maak service file:**
```bash
sudo nano /etc/systemd/system/soar-monitor.service
```

**Inhoud:**
```ini
[Unit]
Description=SOAR Failed Login Monitor
After=network.target

[Service]
Type=simple
User=root
ExecStart=/opt/soar-monitor/send-failed-login-to-aws.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Enable en start service:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable soar-monitor
sudo systemctl start soar-monitor
sudo systemctl status soar-monitor
```

---

## 🧪 Stap 5: Testen

### Test 1: Manual Event Versturen

```bash
aws events put-events \
  --entries '[{
    "Source": "fontys-netlab",
    "DetailType": "Security Event",
    "Detail": "{\"eventType\":\"failed_login\",\"timestamp\":\"2025-10-22T10:00:00Z\",\"sourceIP\":\"192.168.154.50\",\"username\":\"testuser\",\"service\":\"SSH\",\"severity\":\"HIGH\",\"source\":\"fontys-netlab\",\"description\":\"Test failed login\"}"
  }]' \
  --region eu-central-1
```

**Expected output:**
```json
{
    "FailedEntryCount": 0,
    "Entries": [
        {
            "EventId": "xxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
        }
    ]
}
```

### Test 2: Trigger Failed Login

Open **tweede terminal** en probeer foute SSH login:
```bash
# Van je laptop/andere machine:
ssh wronguser@192.168.154.13
# Enter wrong password 3x
```

Check logs op Ubuntu:
```bash
sudo journalctl -u soar-monitor -f
# Je zou moeten zien: "Failed login: wronguser from X.X.X.X"
```

### Test 3: Check AWS Lambda

Check DynamoDB:
```bash
aws dynamodb scan \
  --table-name casestudy2-dev-events \
  --region eu-central-1 \
  --limit 5
```

Check CloudWatch Logs:
- Parser: `/aws/lambda/casestudy2-dev-parser`
- Engine: `/aws/lambda/casestudy2-dev-engine`

---

## 🔍 Troubleshooting

### Service draait niet?
```bash
sudo journalctl -u soar-monitor -n 50
```

### AWS permissions error?
```bash
# Test AWS credentials
aws sts get-caller-identity
aws events list-event-buses --region eu-central-1
```

### Events komen niet aan in Lambda?

1. **Check EventBridge Rule:**
```bash
aws events list-rules --name-prefix casestudy2-dev --region eu-central-1
```

2. **Check SQS Queue:**
```bash
aws sqs get-queue-attributes \
  --queue-url https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-queue \
  --attribute-names All \
  --region eu-central-1
```

3. **Check Dead Letter Queue:**
```bash
aws sqs receive-message \
  --queue-url https://sqs.eu-central-1.amazonaws.com/920120424621/casestudy2-dev-parser-dlq \
  --region eu-central-1
```

---

## 📊 Monitoring

### Realtime logs volgen:
```bash
# Op Ubuntu server:
sudo journalctl -u soar-monitor -f

# AWS CloudWatch:
aws logs tail /aws/lambda/casestudy2-dev-parser --follow --region eu-central-1
```

### Failed login statistics:
```bash
# Laatste 10 failed logins:
sudo grep "Failed password" /var/log/auth.log | tail -10
```

---

## 🎯 Expected Flow:

```
Ubuntu Server (192.168.154.13)
  ↓ SSH Failed Login
/var/log/auth.log
  ↓ Monitored by script
send-failed-login-to-aws.sh
  ↓ AWS CLI
Site-to-Site VPN Tunnel
  ↓
AWS EventBridge (eu-central-1)
  ↓ Event Rule: casestudy2-dev-security-events
SQS Queue: casestudy2-dev-parser-queue
  ↓
Lambda SOAR Pipeline ✅
  ├─ Parser → Engine → Notify → Remediate
  ├─ DynamoDB (event storage)
  └─ SNS (email alert)
```

---

## ✅ Success Criteria:

- [ ] AWS CLI werkt op Ubuntu
- [ ] systemd service draait
- [ ] Test event verstuurd naar EventBridge
- [ ] Failed login trigger test geslaagd
- [ ] Event verschijnt in DynamoDB
- [ ] Email notificatie ontvangen

---

## 🆘 Hulp Nodig?

Als het niet werkt, check:
1. VPN tunnel status
2. AWS credentials validity
3. EventBridge rule enabled
4. SQS queue permissions
5. Lambda function errors in CloudWatch

Stuur logs van:
```bash
sudo journalctl -u soar-monitor -n 100
```
