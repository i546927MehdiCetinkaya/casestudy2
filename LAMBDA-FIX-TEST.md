# 🧪 LAMBDA SOAR TEST - Quick Fix!

## ✅ Fix toegepast:
Parser Lambda ondersteunt nu **meerdere event formaten**:
- ✅ EventBridge events (met `detail` veld)
- ✅ Custom security events (direct format)
- ✅ Failed login events van Fontys Netlab

## 🚀 Test Nu (2 minuten):

### Stap 1: Test Parser Lambda

1. Ga naar AWS Lambda Console:
   https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions/casestudy2-dev-parser

2. Klik **"Test"** tab

3. Create test event: **`FailedLoginFromFontys`**

4. Plak deze **verbeterde** JSON:

```json
{
  "Records": [
    {
      "messageId": "test-456",
      "body": "{\"eventType\":\"failed_login\",\"timestamp\":\"2025-10-22T09:00:00Z\",\"sourceIP\":\"192.168.154.50\",\"username\":\"admin\",\"attemptCount\":5,\"service\":\"SSH\",\"severity\":\"HIGH\",\"source\":\"fontys-netlab\",\"description\":\"5 failed SSH login attempts from Fontys Netlab\"}"
    }
  ]
}
```

5. Klik **"Test"** → Verwacht: ✅ **SUCCESS**

### Stap 2: Check CloudWatch Logs

Open Parser logs:
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fcasestudy2-dev-parser

Je zou moeten zien:
```
Message body: {"eventType":"failed_login",...}
Stored event <UUID> in DynamoDB
Sent event <UUID> to Engine Queue
```

### Stap 3: Check DynamoDB

https://eu-central-1.console.aws.amazon.com/dynamodbv2/home?region=eu-central-1#table?name=casestudy2-dev-events

Klik **"Explore table items"**

Je zou nu een event moeten zien met:
- ✅ `event_name`: "failed_login"
- ✅ `source_ip`: "192.168.154.50"
- ✅ `severity`: "HIGH"  
- ✅ `status`: "analyzed" (als Engine Lambda ook werkt)
- ✅ `raw_event`: Volledige event data

### Stap 4: Check Email

Check inbox: **mehdicetinkaya6132@gmail.com**

Subject: `[SOAR Alert] HIGH severity event detected`

## 🔍 Troubleshooting

### Probleem: Nog steeds lege events?

1. **Check Parser logs** voor errors
2. **Check SQS Dead Letter Queue**:
   ```
   casestudy2-dev-parser-dlq
   ```
3. **Verify EventBridge Rule** is enabled

### Probleem: Slechts 2 Lambda's werken?

Welke 2 werken? Check in CloudWatch:
- Parser ✅ / ❌
- Engine ✅ / ❌  
- Notify ✅ / ❌
- Remediate ✅ / ❌

### Check welke Lambda's errors hebben:

```powershell
# In PowerShell (als AWS credentials werken):
$lambdas = @("parser", "engine", "notify", "remediate")
foreach ($lambda in $lambdas) {
    Write-Host "`n=== casestudy2-dev-$lambda ===" -ForegroundColor Cyan
    aws logs tail "/aws/lambda/casestudy2-dev-$lambda" --since 10m --region eu-central-1
}
```

## 📊 Expected Flow:

```
EventBridge/SQS 
  ↓
Parser Lambda ✅ (parse + classify)
  ↓ (send to Engine Queue)
Engine Lambda ✅ (analyze risk)
  ↓ (send to Notify Queue)  
Notify Lambda ✅ (send SNS email)
  ↓ (send to Remediate Queue)
Remediate Lambda ✅ (execute actions)
  ↓
DynamoDB ✅ (final storage)
```

## 🆘 Nog steeds problemen?

Stuur me de CloudWatch logs van de Lambda die faalt!

1. Ga naar CloudWatch Logs
2. Zoek laatste log stream
3. Copy paste de error message

Dan kan ik precies zien wat er mis gaat! 🔧
