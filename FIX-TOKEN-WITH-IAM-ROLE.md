# 🔧 FIX: Token Issue met IAM Role (Geen IAM User Permissions)

## Het Probleem
- Je kunt geen IAM Users maken (school restrictions)
- SSO token expired elke paar uur
- Je hebt wel IAM Role permissions

## ✅ OPLOSSING: Gebruik IAM Role voor EC2 Instance

### **Vraag eerst**: Is je Ubuntu server een EC2 instance of een externe VM?

---

## 🟢 OPTIE A: Ubuntu is EC2 Instance (BESTE OPLOSSING)

### Stap 1: Maak IAM Role

1. **AWS Console** → **IAM** → **Roles** → **Create role**
2. **Trusted entity type**: AWS service
3. **Use case**: EC2
4. Click **Next**

### Stap 2: Attach Policy

1. Click **Create policy** (nieuw tabblad)
2. Click **JSON** tab
3. Plak deze policy:

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

4. Click **Next**
5. **Policy name**: `SOARMonitorEventBridgePolicy`
6. Click **Create policy**
7. **Ga terug** naar het Create Role tabblad
8. Click 🔄 **Refresh**
9. **Zoek en selecteer**: `SOARMonitorEventBridgePolicy`
10. Click **Next**

### Stap 3: Finalize Role

1. **Role name**: `SOAR-Ubuntu-Monitor-Role`
2. Click **Create role**

### Stap 4: Attach Role aan EC2 Instance

1. **AWS Console** → **EC2** → **Instances**
2. Selecteer je Ubuntu server instance
3. **Actions** → **Security** → **Modify IAM role**
4. **IAM role**: Selecteer `SOAR-Ubuntu-Monitor-Role`
5. Click **Update IAM role**

### Stap 5: Configureer op Ubuntu (GEEN credentials!)

```bash
# Verwijder oude credentials (SSO)
rm -rf ~/.aws/credentials

# Configureer alleen region (GEEN Access Keys!)
mkdir -p ~/.aws
cat > ~/.aws/config << 'EOF'
[default]
region = eu-central-1
output = json
EOF

# Test - dit gebruikt automatisch de EC2 Instance Role!
aws sts get-caller-identity --region eu-central-1
```

**✅ Het zou moeten werken zonder credentials!** De EC2 instance gebruikt automatisch de attached role.

### Stap 6: Test

```bash
# Test EventBridge
aws events put-events \
  --entries '[{
    "Source": "custom.security",
    "DetailType": "Test",
    "Detail": "{\"test\":\"true\"}",
    "EventBusName": "default"
  }]' \
  --region eu-central-1

# Test monitoring script
sudo /usr/local/bin/monitor-failed-logins.sh
```

**✅ Als dit werkt: Je bent klaar! De role blijft permanent, geen expiration!**

---

## 🟡 OPTIE B: Ubuntu is GEEN EC2 (Externe VM of On-Premise)

Dan moet je SSO tokens blijven gebruiken, maar automatisch refreshen.

### Auto-refresh SSO Token Script

Maak een script dat de token automatisch refresht:

```bash
#!/bin/bash
# auto-refresh-sso.sh
# Run dit elke uur via cron

# Check if token is about to expire
aws sts get-caller-identity --region eu-central-1 > /dev/null 2>&1

if [ $? -ne 0 ]; then
    echo "Token expired, need manual refresh"
    echo "Run on Windows: aws sso login --profile fictisb"
    echo "Then copy new credentials to Ubuntu"
    
    # Send alert
    logger -t soar-monitor "AWS SSO token expired! Manual refresh needed."
fi
```

**NADEEL**: Je moet handmatig SSO login doen op Windows elke paar uur en credentials kopiëren.

---

## 🔵 OPTIE C: Vraag aan School om Extra Permissions

### Wat je nodig hebt:

1. **Permission om IAM Users te maken** (CreateUser, CreateAccessKey)
   
   OF

2. **Een bestaande IAM User** die de school voor jou maakt met:
   - Username: `soar-ubuntu-monitor`
   - Policy: `events:PutEvents`
   - Access Keys

---

## 🎯 AANBEVOLEN: Check eerst of het EC2 is

### Op Ubuntu server:

```bash
# Check of dit een EC2 instance is
curl -s http://169.254.169.254/latest/meta-data/instance-id

# Als je een instance ID ziet → HET IS EC2! Gebruik OPTIE A
# Als je "Connection timeout" of error → Het is GEEN EC2, gebruik OPTIE B/C
```

---

## 📋 TL;DR - Wat te doen:

### Als Ubuntu = EC2 Instance:
✅ **Gebruik IAM Role** (OPTIE A) - 5 minuten, werkt permanent!

### Als Ubuntu ≠ EC2 Instance:
1. 🟡 **SSO Auto-refresh** (OPTIE B) - Veel werk, niet ideaal
2. 🔵 **Vraag school om IAM User** (OPTIE C) - Beste als niet-EC2

---

## ❓ Hulp Nodig?

Run dit op Ubuntu om te checken:

```bash
# Is dit EC2?
curl -s http://169.254.169.254/latest/meta-data/instance-id && echo "✅ EC2 Instance - gebruik IAM Role!" || echo "❌ Geen EC2 - gebruik SSO of vraag IAM User"

# Huidige credentials status
aws sts get-caller-identity --region eu-central-1
```

Laat me weten wat je ziet! 🚀
