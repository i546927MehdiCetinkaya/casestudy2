# 🔧 Ubuntu Hybride Setup - Non-EC2 Server

## Je Situatie
- Ubuntu Server: **192.168.154.13** (on-premise/VMware)
- Niet EC2, maar hybride opzet
- Failed login monitoring werkt al! ✅

## 📊 Logs Bekijken

### Op Ubuntu Server:

```bash
# Bekijk alle logs en statistieken
bash scripts/show-ubuntu-logs.sh

# Of handmatig:

# 1. Recent failed logins
sudo grep "Failed password" /var/log/auth.log | tail -20

# 2. SOAR monitor events (gestuurd naar AWS)
sudo grep "soar-monitor" /var/log/syslog | tail -20

# 3. Service logs (als service draait)
sudo journalctl -u failed-login-monitor.service -n 50

# 4. Live monitoring (real-time)
bash scripts/live-monitor.sh
```

## 🔍 Wat te Checken

### Zijn events succesvol verstuurd naar AWS?

```bash
# Check voor success messages
sudo grep "Event sent successfully" /var/log/syslog | tail -10

# Check voor errors
sudo grep "Failed to send event" /var/log/syslog | tail -10
```

Als je **"Event sent successfully"** ziet → ✅ Het werkt!
Als je **"ExpiredToken"** errors ziet → ⚠️ Token is expired

## ✅ Token Fix voor Non-EC2 (Hybride)

Omdat je **geen EC2** bent en **geen IAM User** kunt maken, heb je 2 opties:

### OPTIE 1: Vraag School om IAM User (AANBEVOLEN)

Vraag je docent/admin om:
1. IAM User te maken: `soar-ubuntu-monitor`
2. Policy: `events:PutEvents` permission
3. Access Keys te genereren en aan jou te geven

Dan op Ubuntu:
```bash
aws configure
# Vul Access Key en Secret Access Key in
# GEEN Session Token!
```

### OPTIE 2: SSO Token Handmatig Refreshen

Als token expired:

**Op Windows:**
```powershell
# Login opnieuw
aws sso login --profile fictisb

# Export credentials
aws configure export-credentials --profile fictisb
```

**Op Ubuntu:**
```bash
aws configure
# Plak nieuwe Access Key, Secret Key EN Session Token
```

**NADEEL:** Dit moet je elke paar uur doen! ⚠️

## 📋 Monitoring Script Status

```bash
# Is het script actief?
sudo systemctl status failed-login-monitor.service

# Start script
sudo systemctl start failed-login-monitor.service

# Stop script
sudo systemctl stop failed-login-monitor.service

# Herstart script
sudo systemctl restart failed-login-monitor.service

# Bekijk logs
sudo journalctl -u failed-login-monitor.service -f
```

## 🧪 Test Failed Login

```bash
# In een andere terminal:
ssh wronguser@localhost
# Type verkeerd wachtwoord (3x)

# Check in logs:
sudo grep "soar-monitor" /var/log/syslog | tail -5

# Je zou moeten zien:
# "Failed login event sent: user=wronguser ip=127.0.0.1"
```

## 📊 Statistieken

```bash
# Hoeveel failed logins vandaag?
sudo grep -c "Failed password" /var/log/auth.log

# Hoeveel events naar AWS gestuurd?
sudo grep -c "Failed login event sent" /var/log/syslog

# Top IPs met failed attempts
sudo grep "Failed password" /var/log/auth.log | \
  grep -oP 'from \K[0-9.]+' | \
  sort | uniq -c | sort -rn | head -10
```

## 🔍 Verificatie in AWS

### Op Windows of Ubuntu:

```bash
# Check DynamoDB voor events
aws dynamodb scan \
  --table-name soar-dev-events \
  --region eu-central-1 \
  --max-items 5 \
  --query 'Items[*].[event_id.S, event_name.S, source_ip.S, status.S]' \
  --output table

# Check Lambda logs
aws logs tail /aws/lambda/soar-dev-parser \
  --region eu-central-1 --since 30m

# Check SQS queues
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws sqs get-queue-attributes \
  --queue-url "https://sqs.eu-central-1.amazonaws.com/${ACCOUNT_ID}/soar-dev-parser-queue" \
  --attribute-names ApproximateNumberOfMessages \
  --region eu-central-1
```

## 🎯 Als Alles Werkt

Als je in de logs ziet:
```
Failed login event sent: user=XXX ip=XXX.XXX.XXX.XXX
```

En in AWS DynamoDB events ziet verschijnen → **HET WERKT PERFECT!** ✅

Het enige probleem is de token expiration. Vraag je school om een IAM User voor permanente oplossing.

## 📁 Handige Scripts

```bash
# Bekijk alle logs
bash scripts/show-ubuntu-logs.sh

# Live monitoring
bash scripts/live-monitor.sh

# Test hele systeem (vanuit AWS)
bash scripts/test-soar-system.sh

# Health check (vanuit AWS)
bash scripts/check-soar-health.sh
```

---

**TIP:** Kopieer deze scripts naar je Ubuntu server via SCP:
```powershell
# Op Windows
scp scripts/show-ubuntu-logs.sh student@192.168.154.13:~/
scp scripts/live-monitor.sh student@192.168.154.13:~/

# Dan op Ubuntu
chmod +x show-ubuntu-logs.sh live-monitor.sh
```
