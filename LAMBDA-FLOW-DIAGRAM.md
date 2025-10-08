# Lambda Flow Architecture - Diagram Compliance

## Date: October 8, 2025

## ✅ Architecture Changes According to Diagram

### 1. Lambda Subnet Configuration
- **CIDR**: Changed from `10.0.31.0/24` to `10.0.2.0/24` (as per diagram)
- **Location**: AZ A only (eu-central-1a)
- **VPC Configuration**: All 4 Lambda functions use this subnet

### 2. Lambda Functions Chain (EventBridge → SQS → Lambda Pipeline)

```
┌─────────────────────────────────────────────────────────────────┐
│              EventBridge cs2-event-bus                           │
│          (Receives events from on-premises 192.168.154.13)       │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│         SQS FIFO Queue: cs2-soar-queue.fifo                      │
│                  (Batch 10 msgs)                                 │
└───────────────────────────────┬─────────────────────────────────┘
                                │
                                ▼
    ┌───────────────────────────────────────────────────────┐
    │         Lambda VPC Subnet: 10.0.2.0/24                │
    │                                                         │
    │  ┌──────────────────────────────────────────────┐    │
    │  │  1. Lambda: parser                            │    │
    │  │  - Runtime: Python 3.11                       │    │
    │  │  - Memory: 512 MB                             │    │
    │  │  - Timeout: 30s                               │    │
    │  │  - Function: lambda_handler                   │    │
    │  │                                                │    │
    │  │  Actions:                                     │    │
    │  │  • Parse Event                                │    │
    │  │  • Extract severity                           │    │
    │  │  • Extract source                             │    │
    │  │  • Validate format                            │    │
    │  │  • Write to DynamoDB (cs2-events-table)       │    │
    │  └──────────────────┬───────────────────────────┘    │
    │                     │ Success                         │
    │                     ▼                                 │
    │  ┌──────────────────────────────────────────────┐    │
    │  │  2. Lambda: engine                            │    │
    │  │  - Runtime: Python 3.11                       │    │
    │  │  - Memory: 1024 MB                            │    │
    │  │  - Timeout: 60s                               │    │
    │  │  - Function: lambda_handler                   │    │
    │  │                                                │    │
    │  │  Actions:                                     │    │
    │  │  • Decision Logic                             │    │
    │  │  • if severity == 'HIGH'                      │    │
    │  │  • if source == 'firewall'                    │    │
    │  │  • Determine action                           │    │
    │  │  • Update DynamoDB                            │    │
    │  └──────┬──────────────────────┬────────────────┘    │
    │         │ if HIGH severity     │                      │
    │         ▼                      ▼                      │
    │  ┌──────────────┐      ┌──────────────────────┐     │
    │  │3. Lambda:    │      │ 4. Lambda: notify    │     │
    │  │  remediate   │      │ - Runtime: Python 3.11│     │
    │  │              │      │ - Memory: 256 MB      │     │
    │  │ Actions:     │      │ - Timeout: 30s        │     │
    │  │ • Execute    │      │                       │     │
    │  │   Remediation│      │ Actions:              │     │
    │  │ • Call SOAR  │      │ • Send Notification   │     │
    │  │   API        │      │ • Slack webhook       │     │
    │  │ • Block IP   │      │ • Email (SES)         │     │
    │  │ • Update     │      │ • Log to S3           │     │
    │  │   security   │      │                       │     │
    │  │   group      │      │ ✅ VPC Endpoints:     │     │
    │  │              │      │ - SNS                 │     │
    │  │ ⚠️ KEY:      │      │ - S3                  │     │
    │  │ Calls ALB!   │      │ - CloudWatch Logs     │     │
    │  └──────┬───────┘      └───────────────────────┘     │
    │         │                                             │
    │         │ POST /api/remediate                         │
    │         ▼                                             │
    └───────────────────────────────────────────────────────┘
            │
            │ Internal ALB Call
            ▼
┌───────────────────────────────────────────────────────────────┐
│     Internal ALB: soar-internal-alb                            │
│     Subnet: 10.0.30.0/24 (ALB Private AZ A)                   │
│     Type: internal (NOT internet-facing)                       │
│     Endpoint: http://soar-internal-alb.casestudy2.local       │
└───────────────────────────────┬───────────────────────────────┘
                                │
                                ▼
┌───────────────────────────────────────────────────────────────┐
│              EKS Cluster: cs2-soar                             │
│              Namespace: soar                                   │
│                                                                 │
│  ┌──────────────────────────────────────────────────────┐    │
│  │  Deployment: soar-api-deployment                      │    │
│  │  - Image: soar-api:latest (from ECR via VPC endpoint) │    │
│  │  - Port: 5000                                         │    │
│  │  - Service: ClusterIP                                 │    │
│  │                                                         │    │
│  │  Route: POST /api/remediate                           │    │
│  │  Handler: app.py -> remediate_endpoint()              │    │
│  └──────────────────────────────────────────────────────┘    │
└───────────────────────────────────────────────────────────────┘
```

## 3. VPC Endpoints Configuration (As Per Diagram)

### Gateway Endpoints (Free - No hourly charges)
- **S3**: For Lambda code, logs, notifications storage
- **DynamoDB**: For events table access from Lambda

### Interface Endpoints (~$0.01/hour each)
- **SQS**: For queue operations between Lambdas
- **SNS**: For notifications (Lambda notify → SNS)
- **CloudWatch Logs**: For Lambda logging
- **Lambda**: For cross-Lambda invocations
- **ECR (API + DKR)**: For EKS to pull container images
- **EKS**: For cluster management
- **EC2**: For EKS node management
- **STS**: For IAM role assumptions

### VPC Endpoint Usage per Component:

#### Lambda Parser:
- ✅ **SQS** (via VPC endpoint) - Receive from EventBridge queue
- ✅ **DynamoDB** (via VPC endpoint) - Write parsed events
- ✅ **CloudWatch Logs** (via VPC endpoint) - Logging

#### Lambda Engine:
- ✅ **SQS** (via VPC endpoint) - Receive from parser queue
- ✅ **DynamoDB** (via VPC endpoint) - Read/update events
- ✅ **CloudWatch Logs** (via VPC endpoint) - Logging

#### Lambda Notify:
- ✅ **SQS** (via VPC endpoint) - Receive from engine queue
- ✅ **SNS** (via VPC endpoint) - Send notifications
- ✅ **S3** (via VPC endpoint) - Store notification logs
- ✅ **CloudWatch Logs** (via VPC endpoint) - Logging

#### Lambda Remediate:
- ✅ **SQS** (via VPC endpoint) - Receive from engine queue
- ✅ **DynamoDB** (via VPC endpoint) - Update remediation status
- ✅ **CloudWatch Logs** (via VPC endpoint) - Logging
- ⚠️ **ALB** (internal via private subnet) - POST to EKS SOAR API
- 🌐 **NAT Gateway** - For external firewall API calls (HTTPS)

#### EKS Pods:
- ✅ **ECR API** (via VPC endpoint) - Authenticate to registry
- ✅ **ECR DKR** (via VPC endpoint) - Pull Docker images
- ✅ **S3** (via VPC endpoint) - Access configs/logs
- ✅ **DynamoDB** (via VPC endpoint) - Database operations
- ✅ **CloudWatch Logs** (via VPC endpoint) - Logging

## 4. Key Architecture Decisions

### ✅ Lambda → ALB → EKS Flow
**Why**: 
- Separates concerns: Lambda for event processing, EKS for complex orchestration
- ALB provides load balancing and health checks for EKS pods
- Allows EKS to scale independently of Lambda
- EKS can handle multiple remediation types (firewall, IDS, etc.)

### ✅ Internal ALB (Not Public)
**Why**:
- Security: Only accessible from VPC and Client VPN
- No public internet exposure for remediation API
- Cost: Lower data transfer charges (internal traffic)

### ✅ Single AZ for Lambda (AZ A)
**Why**:
- Simplified architecture as per diagram
- Lower costs (no cross-AZ data transfer)
- Trade-off: Lower availability (acceptable for dev environment)

### ✅ VPC Endpoints for AWS Services
**Why**:
- **Security**: Traffic stays within AWS network
- **Cost**: Reduces NAT Gateway data processing charges
- **Performance**: Lower latency for AWS service calls
- **Compliance**: No internet egress for sensitive data

### ⚠️ NAT Gateway Still Needed
**Why**:
- Lambda remediate calls external firewall API (HTTPS to internet)
- EKS may need to pull from external registries (optional)
- Software updates for EKS nodes

## 5. Lambda Environment Variables (Updated)

### Parser:
```
ENVIRONMENT        = "dev"
ENGINE_QUEUE_URL   = "https://sqs.eu-central-1.amazonaws.com/.../engine-queue"
DYNAMODB_TABLE     = "cs2-dev-events"
LOG_LEVEL          = "INFO"
```

### Engine:
```
ENVIRONMENT            = "dev"
REMEDIATION_QUEUE_URL  = "https://sqs.eu-central-1.amazonaws.com/.../remediation-queue"
NOTIFY_QUEUE_URL       = "https://sqs.eu-central-1.amazonaws.com/.../notify-queue"
DYNAMODB_TABLE         = "cs2-dev-events"
LOG_LEVEL              = "INFO"
```

### Notify:
```
ENVIRONMENT    = "dev"
SNS_TOPIC_ARN  = "arn:aws:sns:eu-central-1:...:security-alerts"
LOG_LEVEL      = "INFO"
```

### Remediate (🔧 UPDATED):
```
ENVIRONMENT     = "dev"
DYNAMODB_TABLE  = "cs2-dev-events"
ALB_ENDPOINT    = "http://soar-internal-alb.casestudy2-dev.internal/api/remediate"  ← NEW
LOG_LEVEL       = "INFO"
```

## 6. Security Groups

### Lambda Security Group:
```
Ingress: NONE (Lambda doesn't need inbound)
Egress:
  - 443 to VPC endpoints (HTTPS)
  - 80/443 to ALB private subnet (10.0.30.0/24)
  - 0.0.0.0/0 via NAT Gateway (for external firewall API)
```

### ALB Security Group:
```
Ingress:
  - 80/443 from VPC CIDR (10.0.0.0/16)
  - 80/443 from Client VPN CIDR (172.16.0.0/22)
Egress:
  - All to EKS private subnets (10.0.10.0/24, 10.0.11.0/24)
```

### VPC Endpoints Security Group:
```
Ingress:
  - 443 from VPC CIDR (10.0.0.0/16)
Egress:
  - All
```

## 7. Testing Checklist

### Lambda Chain:
- [ ] EventBridge → SQS → Parser Lambda
- [ ] Parser → DynamoDB write
- [ ] Parser → Engine Queue
- [ ] Engine → Decision logic (HIGH severity)
- [ ] Engine → Remediation Queue (if HIGH)
- [ ] Engine → Notify Queue
- [ ] Notify → SNS → Slack/Email
- [ ] Remediate → DynamoDB update
- [ ] Remediate → ALB call (internal)
- [ ] ALB → EKS SOAR API

### VPC Endpoints:
- [ ] Lambda can write to DynamoDB without NAT
- [ ] Lambda can send SQS messages without NAT
- [ ] Lambda can publish to SNS without NAT
- [ ] EKS can pull from ECR without NAT
- [ ] Lambda can log to CloudWatch without NAT

### ALB Flow:
- [ ] Lambda remediate can reach internal ALB
- [ ] ALB forwards to EKS pods
- [ ] EKS API responds to remediation request
- [ ] Response logged in DynamoDB

### External Connectivity:
- [ ] Lambda remediate can call external firewall API (via NAT)
- [ ] Verify NAT Gateway usage metrics

## 8. Cost Optimization Notes

### Savings from VPC Endpoints:
- **DynamoDB**: ~500 Lambda calls/hour → ~$7.50/month saved on NAT
- **SQS**: ~1000 messages/hour → ~$15/month saved on NAT
- **SNS**: ~200 notifications/hour → ~$3/month saved on NAT
- **S3**: ~100 log writes/hour → ~$1.50/month saved on NAT
- **Total NAT savings**: ~$27/month

### VPC Endpoint Costs:
- **Gateway endpoints** (S3, DynamoDB): $0 (free)
- **Interface endpoints** (8 endpoints × $0.01/hour × 730 hours): ~$58/month

### Net Cost:
- **Additional cost**: ~$31/month
- **Benefit**: Higher security, better performance, no data transfer limits

## 9. Deployment Order

1. ✅ Update VPC: Lambda subnet to 10.0.2.0/24
2. ✅ Update Lambda remediate: Add ALB_ENDPOINT env var
3. ✅ Update Lambda remediate code: Add requests library + ALB call
4. ✅ Verify VPC endpoints include lambda subnet
5. Deploy Terraform changes
6. Deploy EKS SOAR API with `/api/remediate` endpoint
7. Test Lambda → ALB → EKS flow
8. Monitor CloudWatch Logs for both Lambda and EKS

---

**Status**: ✅ Code Updated - Ready for Deployment
**Architecture**: Compliant with provided diagram
**Flow**: EventBridge → SQS → Lambda (Parser → Engine → Notify/Remediate) → ALB → EKS
