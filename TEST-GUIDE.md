# LAMBDA SOAR TEST GUIDE

## 🧪 Test via AWS Console (Makkelijkste)

### 1. Test Parser Lambda

1. Ga naar: https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions/casestudy2-dev-parser
2. Klik op **"Test"** tab
3. Create new test event met naam: `FailedLoginTest`
4. Plak deze JSON:

```json
{
  "Records": [
    {
      "messageId": "test-123",
      "body": "{\"eventType\":\"failed_login\",\"timestamp\":\"2025-10-22T08:15:00Z\",\"sourceIP\":\"192.168.154.50\",\"username\":\"admin\",\"attemptCount\":5,\"service\":\"SSH\",\"severity\":\"HIGH\",\"description\":\"Multiple failed login attempts from Fontys Netlab\"}"
    }
  ]
}
```

5. Klik **"Test"** - je zou SUCCESS moeten zien!

### 2. Bekijk CloudWatch Logs

**Parser Logs:**
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fcasestudy2-dev-parser

**Engine Logs:**
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fcasestudy2-dev-engine

**Notify Logs:**
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fcasestudy2-dev-notify

**Remediate Logs:**
https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups/log-group/$252Faws$252Flambda$252Fcasestudy2-dev-remediate

### 3. Check DynamoDB Events

Ga naar: https://eu-central-1.console.aws.amazon.com/dynamodbv2/home?region=eu-central-1#table?name=casestudy2-dev-events

Klik **"Explore table items"** - je zou events moeten zien!

### 4. Check SNS Email

Kijk in je email (mehdicetinkaya6132@gmail.com) voor security alerts!

## 🔄 Volledige SOAR Flow Test

### Via EventBridge (Advanced)

1. Ga naar: https://eu-central-1.console.aws.amazon.com/events/home?region=eu-central-1#/eventbus/default
2. Klik **"Send events"**
3. Event source: `custom.security`
4. Detail type: `Security Event`
5. Event detail:

```json
{
  "eventType": "failed_login",
  "timestamp": "2025-10-22T08:15:00Z",
  "sourceIP": "192.168.154.50",
  "username": "admin",
  "attemptCount": 5,
  "service": "SSH",
  "severity": "HIGH",
  "description": "Multiple failed login attempts detected from Fontys Netlab"
}
```

6. Klik **"Send"**

### Verwachte Flow:

```
EventBridge 
  ↓
SQS Queue (casestudy2-dev-parser-queue)
  ↓
Parser Lambda ✅ (parse event data)
  ↓
SQS Queue (casestudy2-dev-engine-queue)
  ↓
Engine Lambda ✅ (analyze threat, determine actions)
  ↓
SQS Queue (casestudy2-dev-notify-queue)
  ↓
Notify Lambda ✅ (send SNS email)
  ↓
SQS Queue (casestudy2-dev-remediate-queue)
  ↓
Remediate Lambda ✅ (execute actions: BLOCK_IP, ALERT_SECURITY_TEAM)
  ↓
DynamoDB (casestudy2-dev-events) ✅ (store event)
```

## 📊 Monitoring

### CloudWatch Insights Query

Ga naar CloudWatch Logs Insights en run deze query:

```
fields @timestamp, @message
| filter @message like /failed_login/
| sort @timestamp desc
| limit 20
```

### Lambda Metrics

Bekijk in CloudWatch Metrics:
- Lambda → By Function Name
- Check: Invocations, Duration, Errors, Throttles

## ✅ Success Criteria

- [ ] Parser Lambda executes zonder errors
- [ ] Engine Lambda analyzes event
- [ ] Notify Lambda sends SNS email (check inbox!)
- [ ] Remediate Lambda logs actions
- [ ] DynamoDB bevat event record
- [ ] CloudWatch logs tonen volledige flow

## 🐛 Troubleshooting

**No events in DynamoDB?**
- Check SQS Dead Letter Queues voor failed messages

**No email received?**
- Check SNS topic subscription is confirmed
- Check spam folder

**Lambda errors?**
- Check CloudWatch Logs voor stack traces
- Verify IAM permissions

## 📝 Quick Links

- **Lambda Functions**: https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions
- **CloudWatch Logs**: https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups
- **DynamoDB Tables**: https://eu-central-1.console.aws.amazon.com/dynamodbv2/home?region=eu-central-1#tables
- **SQS Queues**: https://eu-central-1.console.aws.amazon.com/sqs/v2/home?region=eu-central-1#/queues
- **EventBridge Rules**: https://eu-central-1.console.aws.amazon.com/events/home?region=eu-central-1#/rules
