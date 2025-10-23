# Ubuntu Server Setup Checklist voor SOAR Failed Login Monitoring

## 📋 Wat je moet doen op de Ubuntu server

### 1. **AWS CLI Installeren & Configureren**

```bash
# Installeer AWS CLI en jq
sudo apt update
sudo apt install awscli jq -y

# Verificeer installatie
aws --version
jq --version
```

### 2. **AWS Credentials Configureren**

Je hebt twee opties:

#### **Optie A: IAM User Credentials (Makkelijkst voor testing)**
```bash
# Configureer AWS credentials
aws configure

# Vul in:
# AWS Access Key ID: [Jouw Access Key]
# AWS Secret Access Key: [Jouw Secret Key]
# Default region name: eu-central-1
# Default output format: json
```

#### **Optie B: EC2 Instance Role (Beste practice voor productie)**
Als je Ubuntu server een EC2 instance is, geef het een IAM Role met deze permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "events:PutEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

### 3. **Test AWS Verbinding**

```bash
# Test of AWS CLI werkt
aws sts get-caller-identity --region eu-central-1

# Test EventBridge access
aws events list-event-buses --region eu-central-1
```

### 4. **Monitoring Script Installeren**

```bash
# Kopieer het script naar de server
# (gebruik scp of kopieer de inhoud)
sudo nano /usr/local/bin/monitor-failed-logins.sh

# Plak de inhoud van ubuntu-monitor-failed-logins.sh

# Maak het executable
sudo chmod +x /usr/local/bin/monitor-failed-logins.sh

# Test het script handmatig
sudo /usr/local/bin/monitor-failed-logins.sh
```

### 5. **Script als Service Configureren (Automatisch starten)**

```bash
# Maak systemd service file
sudo nano /etc/systemd/system/failed-login-monitor.service
```

Plak deze inhoud:
```ini
[Unit]
Description=Ubuntu Failed Login Monitor for AWS SOAR
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/monitor-failed-logins.sh
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

```bash
# Reload systemd
sudo systemctl daemon-reload

# Enable service (start bij boot)
sudo systemctl enable failed-login-monitor.service

# Start service
sudo systemctl start failed-login-monitor.service

# Check status
sudo systemctl status failed-login-monitor.service
```

### 6. **Verificatie & Testing**

```bash
# Check of service draait
sudo systemctl status failed-login-monitor.service

# Bekijk logs
sudo journalctl -u failed-login-monitor.service -f

# Test met een failed login
# Open een NIEUWE terminal en probeer in te loggen met verkeerd wachtwoord:
ssh wronguser@localhost

# Je zou in de logs moeten zien:
# "🚨 Failed login detected"
# "✅ Event sent successfully!"
```

### 7. **Check in AWS**

Na een failed login attempt:

```bash
# Check SQS Queue voor messages
aws sqs get-queue-attributes \
  --queue-url https://sqs.eu-central-1.amazonaws.com/YOUR_ACCOUNT/soar-dev-parser-queue \
  --attribute-names ApproximateNumberOfMessages \
  --region eu-central-1

# Check DynamoDB voor events
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --max-items 5
```

### 8. **Troubleshooting Commands**

```bash
# Als events niet aankomen, check:

# 1. Service status
sudo systemctl status failed-login-monitor.service

# 2. Service logs (laatste 50 regels)
sudo journalctl -u failed-login-monitor.service -n 50

# 3. Auth.log (waar failed logins staan)
sudo tail -f /var/log/auth.log

# 4. Test AWS credentials
aws sts get-caller-identity --region eu-central-1

# 5. Test EventBridge direct
aws events put-events \
  --entries file:///path/to/test-ubuntu-event.json \
  --region eu-central-1

# 6. Check IAM permissions
aws iam get-user --region eu-central-1
```

### 9. **Script Stoppen/Herstarten**

```bash
# Stop service
sudo systemctl stop failed-login-monitor.service

# Start service
sudo systemctl start failed-login-monitor.service

# Herstart service
sudo systemctl restart failed-login-monitor.service

# Disable service (stop automatisch starten)
sudo systemctl disable failed-login-monitor.service
```

---

## 🎯 Quick Start Commando's

Als je snel wilt starten:

```bash
# 1. Installeer dependencies
sudo apt update && sudo apt install awscli jq -y

# 2. Configureer AWS
aws configure

# 3. Test AWS
aws sts get-caller-identity --region eu-central-1

# 4. Kopieer script
sudo cp ubuntu-monitor-failed-logins.sh /usr/local/bin/monitor-failed-logins.sh
sudo chmod +x /usr/local/bin/monitor-failed-logins.sh

# 5. Test handmatig
sudo /usr/local/bin/monitor-failed-logins.sh
```

---

## ✅ Checklist

- [ ] AWS CLI geïnstalleerd
- [ ] jq geïnstalleerd  
- [ ] AWS credentials geconfigureerd
- [ ] AWS verbinding getest
- [ ] Script gekopieerd naar /usr/local/bin/
- [ ] Script executable gemaakt
- [ ] Script handmatig getest
- [ ] Systemd service aangemaakt
- [ ] Service enabled & started
- [ ] Failed login getest
- [ ] Event zichtbaar in AWS (SQS/DynamoDB)
- [ ] Lambda notificatie ontvangen

---

## 🔍 Expected Output

Als alles werkt zie je in de logs:

```
🔍 Starting Ubuntu Failed Login Monitor...
Monitoring: /var/log/auth.log
Region: eu-central-1
✅ AWS CLI en jq gevonden
✅ Log file gevonden
🚀 Start monitoring...

🚨 Failed login detected:
   Time: 2025-10-23T14:30:00Z
   User: testuser
   IP: 192.168.1.100
   📤 Sending to EventBridge...
   ✅ Event sent successfully!
```

En in AWS CloudWatch Logs voor de Lambda functies zie je de verwerking.
