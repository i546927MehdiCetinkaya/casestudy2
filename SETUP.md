# Ubuntu SOAR Integration Setup

Quick setup guide voor Ubuntu server 192.168.154.13

## 1. Prerequisites op Ubuntu

```bash
# Update systeem
sudo apt update && sudo apt upgrade -y

# Installeer AWS CLI en jq
sudo apt install awscli jq -y

# Verificatie
aws --version
jq --version
```

## 2. AWS Credentials configureren

Gebruik de **GitHub OIDC credentials** (AWS_ACCESS_KEY_ID en AWS_SECRET_ACCESS_KEY):

```bash
# Configureer AWS CLI
aws configure
# AWS Access Key ID: [GitHub Secret]
# AWS Secret Access Key: [GitHub Secret]
# Default region: eu-central-1
# Default output format: json

# Test credentials
aws sts get-caller-identity
```

## 3. Script installeren

```bash
# Maak directory
sudo mkdir -p /opt/soar-monitor
cd /opt/soar-monitor

# Download script (vervang USERNAME en TOKEN)
curl -o monitor.sh https://raw.githubusercontent.com/i546927MehdiCetinkaya/casestudy2/main/scripts/ubuntu-monitor-failed-logins.sh

# Of upload via SCP:
# scp scripts/ubuntu-monitor-failed-logins.sh user@192.168.154.13:/tmp/
# sudo mv /tmp/ubuntu-monitor-failed-logins.sh /opt/soar-monitor/monitor.sh

# Update ROLE_ARN in script (check GitHub Actions output)
ROLE_ARN="arn:aws:iam::920120424621:role/casestudy2-dev-ubuntu-eventbridge"
sudo sed -i "s|REPLACE_WITH_ROLE_ARN|$ROLE_ARN|g" /opt/soar-monitor/monitor.sh

# Maak executable
sudo chmod +x /opt/soar-monitor/monitor.sh
```

## 4. Systemd Service aanmaken

```bash
# Create service file
sudo tee /etc/systemd/system/soar-monitor.service > /dev/null <<EOF
[Unit]
Description=SOAR Failed Login Monitor
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/soar-monitor
ExecStart=/opt/soar-monitor/monitor.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable soar-monitor
sudo systemctl start soar-monitor

# Check status
sudo systemctl status soar-monitor
```

## 5. Testen

```bash
# Test met opzettelijk foute login (vanaf andere machine):
ssh invaliduser@192.168.154.13

# Check logs
sudo journalctl -u soar-monitor -f

# Check syslog
sudo tail -f /var/log/syslog | grep soar-monitor
```

## 6. Verificatie in AWS

1. **CloudWatch Logs**: Check Parser Lambda logs
2. **DynamoDB**: Check `casestudy2-dev-events` table
3. **SNS Email**: Check inbox voor security alerts

## Troubleshooting

**Service start niet:**
```bash
sudo journalctl -u soar-monitor -n 50
```

**AWS credentials fout:**
```bash
aws sts get-caller-identity
aws sts assume-role --role-arn $ROLE_ARN --role-session-name test
```

**Log file niet gevonden:**
```bash
ls -la /var/log/auth.log
sudo chmod 644 /var/log/auth.log
```

## Flow Diagram

```
Ubuntu auth.log
    ↓ [tail -f]
Bash Script (monitor.sh)
    ↓ [grep "Failed password"]
Parse username + IP
    ↓ [aws sts assume-role]
GitHub OIDC Role
    ↓ [AssumeRole]
Ubuntu EventBridge Role
    ↓ [aws events put-events]
EventBridge (custom.security)
    ↓
SQS Queue
    ↓
Parser Lambda
    ↓
Engine Lambda (risk_score: 70)
    ↓
Notify Lambda (SNS email)
    ↓
Remediate Lambda
    ↓
DynamoDB (event stored)
```

## Commands Reference

```bash
# Start/Stop service
sudo systemctl start soar-monitor
sudo systemctl stop soar-monitor
sudo systemctl restart soar-monitor

# Check status
sudo systemctl status soar-monitor

# View logs (live)
sudo journalctl -u soar-monitor -f

# View logs (last 100 lines)
sudo journalctl -u soar-monitor -n 100

# Test script manually
sudo /opt/soar-monitor/monitor.sh

# Check failed logins in auth.log
sudo grep "Failed password" /var/log/auth.log | tail -20
```
