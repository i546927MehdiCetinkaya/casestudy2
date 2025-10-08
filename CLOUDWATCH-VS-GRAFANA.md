# CloudWatch vs Grafana/Prometheus/Loki - Decision Document

## Current Setup Analysis

### CloudWatch Usage in Infrastructure:

#### 1. ❌ CloudWatch Logs (NIET NODIG - Gebruik Loki)
**Locatie**: `lambda.tf` - CloudWatch Log Groups per Lambda
```terraform
resource "aws_cloudwatch_log_group" "parser" {
  name = "/aws/lambda/${aws_lambda_function.parser.function_name}"
}
```

**Probleem**: 
- Je gebruikt Loki voor log aggregation
- Lambda logs kunnen naar Loki via log shipping
- CloudWatch Logs kost geld per GB

**Oplossing**: Verwijderen of optioneel maken

---

#### 2. ✅ EventBridge (WEL NODIG - Event Routing)
**Locatie**: `eventbridge.tf` + `services.tf`

**EventBridge Rule 1 - On-Premises Events**:
```
On-Premises Webserver (192.168.154.13)
    ↓ HTTP POST
EventBridge (custom.onprem source)
    ↓
SQS Parser Queue
    ↓
Lambda Parser
```

**EventBridge Rule 2 - CloudTrail Events**:
```
AWS CloudTrail API calls
    ↓
EventBridge (aws.cloudtrail source)
    ↓
SQS Parser Queue
    ↓
Lambda Parser
```

**Waarom NODIG**: Dit is event routing, niet monitoring!

---

#### 3. ✅ Grafana + Prometheus + Loki (Monitoring Stack)
**Locatie**: `kubernetes/prometheus.yaml`, `kubernetes/grafana.yaml`

**Purpose**:
- **Prometheus**: Metrics collection (CPU, memory, requests, etc.)
- **Grafana**: Visualization dashboard
- **Loki**: Log aggregation (EKS pod logs)

**Flow**:
```
EKS Pods → Prometheus (metrics) → Grafana
EKS Pods → Loki (logs) → Grafana
Lambda → ??? (currently CloudWatch Logs)
```

---

## Decisions

### ✅ KEEP: EventBridge
**Reason**: Event routing van on-premises en CloudTrail naar Lambda
**NOT** for monitoring - for event processing!

### ❌ REMOVE: CloudWatch Log Groups (Lambda logs)
**Reason**: Je gebruikt Loki voor logs

**Alternative**:
1. Lambda → Kinesis Data Firehose → S3 → Loki
2. Lambda → CloudWatch Logs → Lambda Log Shipper → Loki
3. Or keep CloudWatch Logs for Lambda (simplest)

### ✅ KEEP: Grafana + Prometheus + Loki
**Reason**: EKS monitoring en logging

---

## Recommended Changes

### Option 1: Remove CloudWatch Logs Completely
```terraform
# lambda.tf - Remove these:
# resource "aws_cloudwatch_log_group" "parser" { ... }
# resource "aws_cloudwatch_log_group" "engine" { ... }
# resource "aws_cloudwatch_log_group" "notify" { ... }
# resource "aws_cloudwatch_log_group" "remediate" { ... }

# Add Lambda environment variable:
LOG_DESTINATION = "loki"
LOKI_ENDPOINT = "http://loki.monitoring.svc.cluster.local:3100"
```

**Impact**:
- Lambda logs NOT in CloudWatch
- Need custom log shipper to Loki
- More complex setup

### Option 2: Keep CloudWatch Logs for Lambda (AANBEVOLEN)
```terraform
# Keep existing CloudWatch Log Groups
# Lambda logs → CloudWatch Logs (automatic)
# Ship to Loki later if needed
```

**Impact**:
- Lambda logs still in CloudWatch (costs ~$0.50/month)
- Simple, works out of the box
- Can add Loki shipper later

### Option 3: Hybrid Approach
```terraform
# Lambda → CloudWatch Logs (short retention)
resource "aws_cloudwatch_log_group" "parser" {
  retention_in_days = 3  # ← Reduce from 7 to 3 days
}

# CloudWatch Logs → Lambda Shipper → Loki
# (for long-term storage in Loki)
```

---

## What to Fix NOW

### 1. ✅ Fix Duplicate Resource (DONE)
```terraform
# services.tf - Renamed
resource "aws_cloudwatch_event_target" "cloudtrail_parser_queue" {
  # was: parser_queue
}
```

### 2. ✅ Keep EventBridge (Event Routing)
```terraform
# eventbridge.tf - KEEP
resource "aws_cloudwatch_event_rule" "onprem_events" { ... }
resource "aws_cloudwatch_event_target" "parser_queue" { ... }

# services.tf - KEEP
resource "aws_cloudwatch_event_rule" "cloudtrail_events" { ... }
resource "aws_cloudwatch_event_target" "cloudtrail_parser_queue" { ... }
```

### 3. ⚠️ Decision Needed: CloudWatch Logs
**Option A**: Keep (simplest, costs ~$0.50/month)
**Option B**: Remove + custom Loki integration (complex)
**Option C**: Keep with short retention (3 days)

---

## Cost Comparison

### Current (with CloudWatch Logs):
- CloudWatch Logs: ~$0.50/GB ingested (~$3/month for dev)
- EventBridge: ~$1/million events (~$0.10/month)
- Prometheus + Grafana + Loki: Free (self-hosted in EKS)

### Without CloudWatch Logs:
- CloudWatch Logs: $0
- EventBridge: ~$0.10/month
- Prometheus + Grafana + Loki: Free
- **Savings**: ~$3/month

---

## Recommendation

### For DEV Environment:
✅ **Keep CloudWatch Logs for Lambda** (simplicity > cost)
✅ **Keep EventBridge** (required for event routing)
✅ **Keep Grafana + Prometheus + Loki** (EKS monitoring)

**Why**:
- Lambda logs → CloudWatch is automatic (no setup)
- EventBridge ≠ monitoring (it's event routing)
- Grafana stack for EKS is working
- Total cost: ~$3/month (acceptable for dev)

### For PROD Environment:
✅ Ship Lambda logs to Loki (long-term storage)
✅ Keep CloudWatch Logs with 1-day retention (debugging)
✅ All logs centralized in Loki/Grafana

---

**Status**: ✅ Duplicate fixed
**Next**: Beslissen over CloudWatch Logs
