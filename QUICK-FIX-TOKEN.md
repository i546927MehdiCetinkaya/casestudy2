# 🔴 FIX: AWS Token Expired Issue

## Het Probleem
Je SSO session token is **expired**. SSO tokens zijn tijdelijk en niet geschikt voor 24/7 monitoring scripts.

---

## ✅ OPLOSSING: Maak IAM User (5 minuten)

### 📋 STAP 1: Maak IAM User in AWS Console

1. **Open AWS Console** → Zoek naar **IAM**
2. Click **Users** (links) → **Create user**
3. **User name**: `soar-ubuntu-monitor`
4. Click **Next**

### 📋 STAP 2: Geef Permissions

1. Selecteer **Attach policies directly**
2. Click **Create policy** (nieuw tabblad opent)
3. Click **JSON** tab
4. **Kopieer deze policy** (of gebruik `iam-policy-soar-monitor.json`):

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

5. Click **Next**
6. **Policy name**: `SOARMonitorEventBridgePolicy`
7. Click **Create policy**
8. **Ga terug** naar het Create User tabblad
9. Click **🔄 Refresh** bij de policies lijst
10. **Zoek en selecteer**: `SOARMonitorEventBridgePolicy`
11. Click **Next** → **Create user**

### 📋 STAP 3: Genereer Access Keys

1. Click op de **user** (soar-ubuntu-monitor)
2. Click **Security credentials** tab
3. Scroll naar **Access keys** → Click **Create access key**
4. **Use case**: Select **Application running outside AWS**
5. Click **Next** → Click **Create access key**
6. **⚠️ BELANGRIJK**: Download of kopieer **Access key** en **Secret access key**
   - Je kunt de Secret access key maar **1 keer** zien!

---

## 🖥️ STAP 4: Configureer op Ubuntu Server

Voer dit uit op je **Ubuntu server**:

```bash
# Verwijder oude SSO credentials
rm -rf ~/.aws/credentials ~/.aws/config

# Configureer met IAM User credentials
aws configure
```

**Vul in**:
- **AWS Access Key ID**: `[Plak je Access Key]`
- **AWS Secret Access Key**: `[Plak je Secret Key]`
- **Default region name**: `eu-central-1`
- **Default output format**: `json`

**⚠️ LET OP**: Als het vraagt om "AWS Session Token" - **laat dit LEEG!** Druk gewoon Enter.

---

## 🧪 STAP 5: Test of het werkt

```bash
# Test credentials
aws sts get-caller-identity --region eu-central-1

# Je moet nu je IAM User zien, niet meer de SSO role! ✅

# Test EventBridge
aws events put-events \
  --entries '[{
    "Source": "custom.security",
    "DetailType": "Test",
    "Detail": "{\"test\":\"true\"}",
    "EventBusName": "default"
  }]' \
  --region eu-central-1

# Als dit werkt zonder error → SUCCESS! ✅
```

---

## 🚀 STAP 6: Test Monitoring Script

```bash
# Start het monitoring script
sudo /usr/local/bin/monitor-failed-logins.sh

# In een ANDERE terminal:
ssh wronguser@localhost
# (probeer verkeerd wachtwoord)

# Je moet nu zien:
# ✅ Event sent successfully!
# (GEEN "ExpiredToken" error meer!)
```

---

## 🎯 Quick Setup Script

Of gebruik het automatische setup script:

```bash
# Kopieer het script naar Ubuntu
# Dan run:
bash scripts/setup-iam-credentials.sh

# Dit script helpt je stap-voor-stap
```

---

## ❓ Waarom IAM User beter is dan SSO?

| Feature | SSO Token | IAM User Access Keys |
|---------|-----------|---------------------|
| **Geldigheid** | 1-12 uur | Permanent* |
| **Monitoring 24/7** | ❌ Nee (expired) | ✅ Ja |
| **Auto-renewal** | ❌ Handmatig | ✅ Niet nodig |
| **Best for** | Developers | Applications |

\* Tot je ze roteert (best practice: elke 90 dagen)

---

## 🔄 Alternatief: Refresh SSO (Tijdelijk)

Als je ECHT SSO wilt gebruiken (niet aanbevolen voor monitoring):

**Op Windows**:
```powershell
# Login opnieuw
aws sso login --profile fictisb

# Bekijk nieuwe credentials
aws configure export-credentials --profile fictisb
```

**Op Ubuntu**: Kopieer de nieuwe credentials (inclusief session token)

**NADEEL**: Dit moet je elke paar uur herhalen! ❌

---

## 🎉 Als je IAM User hebt geconfigureerd:

Ga verder met het [UBUNTU-STAPPENPLAN.txt](UBUNTU-STAPPENPLAN.txt) vanaf **STAP 8** (Systemd service).

Je credentials werken nu **24/7** zonder expiration! ✅
