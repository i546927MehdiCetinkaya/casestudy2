# AWS SSO Credentials Fix voor Ubuntu Server

## 🔴 Probleem: ExpiredTokenException

Je SSO session token is verlopen. SSO tokens zijn tijdelijk en moeten regelmatig vernieuwd worden.

## ✅ BESTE OPLOSSING: IAM User met Access Keys

### Stap 1: Maak IAM User in AWS Console

1. **Open AWS Console** → IAM → Users → Create User
2. **Username**: `soar-ubuntu-monitor`
3. **Permissions**: Attach policies directly
4. **Policy**: Maak custom policy:

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

5. **Create User**

### Stap 2: Genereer Access Keys

1. Click op de user → **Security credentials** tab
2. Scroll naar **Access keys** → **Create access key**
3. Use case: **Application running outside AWS**
4. **Create access key**
5. **Download** of kopieer de keys (LET OP: Je kunt de Secret Key maar 1x zien!)

### Stap 3: Configureer op Ubuntu Server

```bash
# Verwijder oude (SSO) credentials
rm -rf ~/.aws/credentials ~/.aws/config

# Configureer met IAM User credentials (ZONDER session token!)
aws configure

# Vul in:
# AWS Access Key ID: [De Access Key van de IAM User]
# AWS Secret Access Key: [De Secret Key van de IAM User]  
# Default region name: eu-central-1
# Default output format: json
```

**LET OP**: Als het vraagt om "AWS Session Token" - laat dit LEEG! Druk gewoon Enter.

### Stap 4: Test

```bash
# Test credentials
aws sts get-caller-identity --region eu-central-1

# Test EventBridge
aws events put-events \
  --entries '[{
    "Source": "custom.security",
    "DetailType": "Test",
    "Detail": "{\"test\":\"true\"}",
    "EventBusName": "default"
  }]' \
  --region eu-central-1

# Als dit werkt zonder "ExpiredToken" error, ben je klaar! ✅
```

### Stap 5: Test Monitoring Script

```bash
sudo /usr/local/bin/monitor-failed-logins.sh

# In andere terminal:
ssh wronguser@localhost
# (probeer verkeerd wachtwoord)

# Je moet nu zien: ✅ Event sent successfully!
```

---

## 🔄 ALTERNATIEF: Refresh SSO Token (Tijdelijk)

Als je per se SSO wilt gebruiken:

### Op Windows (waar je SSO login hebt):

```powershell
# Login opnieuw
aws sso login --profile fictisb

# Bekijk credentials
cat $env:USERPROFILE\.aws\credentials

# Of
aws configure export-credentials --profile fictisb --format env-no-export
```

Dit geeft je nieuwe credentials met een nieuwe session token.

### Kopieer naar Ubuntu:

```bash
# Op Ubuntu
aws configure

# Plak de NIEUWE:
# - Access Key ID
# - Secret Access Key  
# - Session Token (als gevraagd)
```

**NADEEL**: Dit moet je elke keer doen als de token expired (vaak na 1-12 uur).

---

## ⚡ BESTE PRACTICE: EC2 Instance Role

Als je Ubuntu server een EC2 instance is:

1. **AWS Console** → EC2 → Instances
2. Select je instance → **Actions** → **Security** → **Modify IAM role**
3. **Create new IAM role** met deze policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["events:PutEvents"],
      "Resource": "*"
    }
  ]
}
```
4. Attach role to instance
5. **Op Ubuntu**: Verwijder credentials file
```bash
rm -rf ~/.aws/credentials
# Alleen config houden met region
echo "[default]
region = eu-central-1
output = json" > ~/.aws/config
```

AWS CLI gebruikt dan automatisch de instance role (geen credentials nodig!).

---

## 🎯 QUICK FIX (DO THIS NOW):

```bash
# 1. Verwijder oude credentials
rm -rf ~/.aws/credentials ~/.aws/config

# 2. Maak IAM User in AWS Console met EventBridge permissions
#    (zie stap 1-2 hierboven)

# 3. Configureer met IAM User keys
aws configure
# (GEEN session token invullen!)

# 4. Test
aws sts get-caller-identity --region eu-central-1

# 5. Test monitoring
sudo /usr/local/bin/monitor-failed-logins.sh
```

---

## 📝 IAM Policy voor SOAR Monitor

Minimale permissions die je nodig hebt:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPutEventsToEventBridge",
      "Effect": "Allow",
      "Action": [
        "events:PutEvents"
      ],
      "Resource": "*"
    }
  ]
}
```

Save dit als: `SOARMonitorPolicy`

---

## ❓ Waarom werkt SSO niet goed?

- SSO tokens zijn **tijdelijk** (1-12 uur)
- Monitoring script draait **24/7**
- Token expired → script werkt niet meer
- IAM User Access Keys zijn **permanent** (tot je ze roteert)

Voor een **monitoring script dat 24/7 draait** heb je permanente credentials nodig!
