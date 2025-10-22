# Ubuntu SOAR Integration Setup

Quick setup guide voor Ubuntu server 192.168.154.13

## 1. Prerequisites op Ubuntu

```bash
# Update systeem
sudo apt update && sudo apt upgrade -y

# Installeer jq
sudo apt install jq unzip curl -y

# Installeer AWS CLI v2 (voor Ubuntu 24.04)
cd /tmp
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Of gebruik snap (met --classic flag):
# sudo snap install aws-cli --classic

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

# Download script
curl -o monitor.sh https://raw.githubusercontent.com/i546927MehdiCetinkaya/casestudy2/main/scripts/ubuntu-monitor-failed-logins.sh

# Maak executable
sudo chmod +x /opt/soar-monitor/monitor.sh

# Test script (gebruik Ctrl+C om te stoppen)
sudo ./monitor.sh
```

## 4. Systemd Service aanmaken

```bash
# Create service file
sudo tee /etc/systemd/system/soar-monitor.service > /dev/null <<'EOF'
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
Environment="AWS_CONFIG_FILE=/root/.aws/config"
Environment="AWS_SHARED_CREDENTIALS_FILE=/root/.aws/credentials"

[Install]
WantedBy=multi-user.target
EOF

# Kopieer AWS credentials naar root
sudo mkdir -p /root/.aws
sudo cp ~/.aws/config /root/.aws/
sudo cp ~/.aws/credentials /root/.aws/

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable soar-monitor
sudo systemctl start soar-monitor

# Check status
sudo systemctl status soar-monitor

# View logs (live)
sudo journalctl -u soar-monitor -f
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
