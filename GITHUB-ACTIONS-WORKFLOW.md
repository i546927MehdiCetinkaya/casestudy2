# GitHub Actions Deployment Workflow

## Workflow Triggers

### 🔄 Automatische Deployment
```
Push to main branch
    ↓
Changes detected in:
├── terraform/**    → Full infrastructure deployment
├── lambda/**       → Lambda function updates
├── docker/**       → Container image rebuild
└── kubernetes/**   → EKS deployment updates
```

### 🎯 Handmatige Deployment
```
GitHub Actions UI → "Deploy to Dev" → Run workflow

Options:
├── Deploy Terraform:  ☑ true / ☐ false
├── Deploy Lambda:     ☑ true / ☐ false
└── Deploy EKS:        ☑ true / ☐ false
```

## Workflow Stages

### Stage 1: Terraform Infrastructure (5-10 min)

```
┌─────────────────────────────────────────────────────────┐
│              Terraform Deploy Job                        │
│                                                           │
│  1. Checkout code                                        │
│  2. Configure AWS credentials (OIDC)                     │
│  3. Setup Terraform 1.6.0                                │
│  4. terraform init                                       │
│  5. terraform plan -out=tfplan                           │
│  6. Upload plan as artifact                              │
│  7. terraform apply -auto-approve                        │
│  8. Get outputs (EKS cluster name, VPC ID, etc.)         │
│                                                           │
│  Deploys:                                                │
│  ✓ VPC (10.0.0.0/16)                                    │
│    - Public subnets (AZ A, B)                           │
│    - Private EKS subnets (AZ A, B)                      │
│    - ALB private subnet (AZ A - 10.0.30.0/24)          │
│    - Lambda private subnet (AZ A - 10.0.2.0/24)        │
│  ✓ VPC Endpoints (S3, DynamoDB, ECR, SQS, SNS)          │
│  ✓ EKS Cluster (Kubernetes 1.28)                        │
│  ✓ Lambda Functions (Parser, Engine, Notify, Remediate) │
│  ✓ DynamoDB Table (events)                              │
│  ✓ SQS Queues (4 queues)                                │
│  ✓ SNS Topics (security-alerts)                         │
│  ✓ EventBridge (on-premises integration)                │
│  ✓ VPN (Site-to-Site + Client VPN)                      │
│  ✓ Route53 Private Hosted Zone                          │
│  ✓ Internal ALB                                          │
│                                                           │
│  Outputs:                                                │
│  → eks_cluster_name                                      │
│  → vpc_id                                                │
│  → lambda_function_arns                                  │
│  → alb_dns_name                                          │
└─────────────────────────────────────────────────────────┘
                        ↓
                (Pass outputs to next jobs)
```

### Stage 2: Build & Push Docker Images (3-5 min)

```
┌─────────────────────────────────────────────────────────┐
│         Build & Push Job (Matrix Strategy)               │
│                                                           │
│  Parallel builds for:                                    │
│  ├── soar-api                                            │
│  ├── soar-processor                                      │
│  └── soar-remediation                                    │
│                                                           │
│  For each service:                                       │
│  1. Checkout code                                        │
│  2. Configure AWS credentials                            │
│  3. Login to ECR                                         │
│  4. docker build -t <service>:${GITHUB_SHA}              │
│  5. docker tag <service>:latest                          │
│  6. docker push <service>:${GITHUB_SHA}                  │
│  7. docker push <service>:latest                         │
│                                                           │
│  Registry: 920120424621.dkr.ecr.eu-central-1...         │
│  Path: casestudy2/dev/<service>                          │
│  Tags: [latest, git-sha]                                 │
└─────────────────────────────────────────────────────────┘
                        ↓
```

### Stage 3: Deploy Lambda Functions (2-3 min)

```
┌─────────────────────────────────────────────────────────┐
│              Deploy Lambda Job                           │
│                                                           │
│  For each Lambda function:                               │
│  ├── parser/                                             │
│  ├── engine/                                             │
│  ├── notify/                                             │
│  └── remediate/                                          │
│                                                           │
│  Steps per function:                                     │
│  1. cd lambda/<function>/                                │
│  2. pip install -r requirements.txt -t .                 │
│  3. zip -r <function>.zip .                              │
│  4. aws lambda update-function-code \                    │
│       --function-name casestudy2-dev-<function> \        │
│       --zip-file fileb://<function>.zip                  │
│                                                           │
│  Updates:                                                │
│  ✓ casestudy2-dev-parser                                │
│  ✓ casestudy2-dev-engine                                │
│  ✓ casestudy2-dev-notify                                │
│  ✓ casestudy2-dev-remediate                             │
└─────────────────────────────────────────────────────────┘
                        ↓
```

### Stage 4: Deploy to EKS (5-8 min)

```
┌─────────────────────────────────────────────────────────┐
│                Deploy EKS Job                            │
│                                                           │
│  1. Checkout code                                        │
│  2. Configure AWS credentials                            │
│  3. Update kubeconfig (EKS cluster)                      │
│     aws eks update-kubeconfig --name casestudy2-dev-eks  │
│                                                           │
│  4. Deploy Kubernetes resources:                         │
│     kubectl apply -f kubernetes/namespace.yaml           │
│     kubectl apply -f kubernetes/service-account.yaml     │
│     kubectl apply -f kubernetes/soar-api-deployment.yaml │
│     kubectl apply -f kubernetes/soar-processor-deploy... │
│     kubectl apply -f kubernetes/soar-remediation-depl... │
│     kubectl apply -f kubernetes/ingress.yaml             │
│                                                           │
│  5. Deploy Monitoring Stack:                             │
│     kubectl apply -f kubernetes/prometheus.yaml          │
│     kubectl apply -f kubernetes/grafana.yaml             │
│                                                           │
│  6. Restart Deployments (rolling update):                │
│     kubectl rollout restart deployment/soar-api          │
│     kubectl rollout restart deployment/soar-processor    │
│     kubectl rollout restart deployment/soar-remediation  │
│                                                           │
│  7. Wait for Deployments (timeout 300s):                 │
│     kubectl wait --for=condition=available deployment/.. │
│                                                           │
│  8. Get Endpoints:                                       │
│     ✓ SOAR API Service                                   │
│     ✓ Internal ALB hostname                              │
│     ✓ Ingress details                                    │
│     ✓ Grafana endpoint                                   │
│     ✓ Lambda function list                               │
│     ✓ VPC endpoints status                               │
│                                                           │
│  Deployments:                                            │
│  ✓ soar-api (2 replicas) → ClusterIP                    │
│  ✓ soar-processor (1 replica) → ClusterIP               │
│  ✓ soar-remediation (1 replica) → ClusterIP             │
│  ✓ Prometheus → monitoring namespace                     │
│  ✓ Grafana → monitoring namespace                        │
└─────────────────────────────────────────────────────────┘
                        ↓
```

### Stage 5: Notify Deployment Status

```
┌─────────────────────────────────────────────────────────┐
│              Notification Job                            │
│                                                           │
│  ✅ Success:                                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ✅ Deployment to Dev environment successful!     │   │
│  │                                                   │   │
│  │ 🏗️  Infrastructure Details:                     │   │
│  │    EKS Cluster: casestudy2-dev-eks               │   │
│  │    Region: eu-central-1                          │   │
│  │                                                   │   │
│  │ 🔧 Components Deployed:                          │   │
│  │    ✓ Terraform Infrastructure                    │   │
│  │    ✓ Lambda Functions (4)                        │   │
│  │    ✓ EKS Deployments (3)                         │   │
│  │    ✓ Monitoring Stack                            │   │
│  │                                                   │   │
│  │ 📊 Access Points:                                │   │
│  │    • Internal ALB: (see kubectl output)          │   │
│  │    • Client VPN: Required for monitoring         │   │
│  │    • Lambda Flow: EventBridge → ALB → EKS        │   │
│  │                                                   │   │
│  │ 🔍 Next Steps:                                   │   │
│  │    1. Connect to Client VPN                      │   │
│  │    2. Access Grafana for monitoring              │   │
│  │    3. Test Lambda flow                           │   │
│  │    4. Verify VPC endpoints                       │   │
│  └─────────────────────────────────────────────────┘   │
│                                                           │
│  ❌ Failure:                                             │
│  ┌─────────────────────────────────────────────────┐   │
│  │ ❌ Deployment to Dev environment failed!         │   │
│  │ Check workflow logs for details                  │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Conditional Execution

### Manual Trigger Controls

```yaml
Jobs Execution Matrix:

workflow_dispatch inputs:
├── deploy_terraform: 'true'
│   └── terraform job: ✅ RUNS
├── deploy_terraform: 'false'
│   └── terraform job: ⏭️  SKIPPED

├── deploy_lambda: 'true'
│   └── deploy-lambda job: ✅ RUNS (if terraform success/skipped)
├── deploy_lambda: 'false'
│   └── deploy-lambda job: ⏭️  SKIPPED

├── deploy_eks: 'true'
│   └── build-and-push job: ✅ RUNS (if terraform success/skipped)
│   └── deploy-eks job: ✅ RUNS (if terraform and build success/skipped)
└── deploy_eks: 'false'
    └── build-and-push job: ⏭️  SKIPPED
    └── deploy-eks job: ⏭️  SKIPPED
```

### Auto-Deploy Triggers

```yaml
Push to main branch:
  Changes in terraform/**     → All jobs run
  Changes in lambda/**        → terraform (skip) → deploy-lambda → notify
  Changes in docker/**        → terraform (skip) → build-and-push → deploy-eks
  Changes in kubernetes/**    → terraform (skip) → build-and-push → deploy-eks
  
No matching changes:          → No workflow triggered
```

## Deployment Times

| Stage | Duration | Parallel |
|-------|----------|----------|
| Terraform | 5-10 min | No |
| Docker Build | 3-5 min | Yes (3 images) |
| Lambda Deploy | 2-3 min | No (sequential) |
| EKS Deploy | 5-8 min | No |
| **Total** | **15-26 min** | Mixed |

**Optimizations**:
- Docker images build in parallel (matrix strategy)
- Lambda functions could be parallelized with matrix strategy
- EKS deployments use rolling updates (zero downtime)

## Workflow Artifacts

### Uploaded Artifacts:
1. **terraform-plan** (retention: 7 days)
   - Contents: `plan.txt` (human-readable Terraform plan)
   - Usage: Review changes before apply

### Download Artifacts:
```bash
# Via GitHub UI
Actions → Deploy to Dev → <run> → Artifacts → terraform-plan

# Or via GitHub CLI
gh run download <run-id> --name terraform-plan
```

## Security & Permissions

### AWS Authentication:
- **Method**: OIDC (OpenID Connect) - No long-lived credentials
- **Role**: `arn:aws:iam::920120424621:role/githubrepo`
- **Trust Policy**: GitHub Actions federated identity

### Required IAM Permissions:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "lambda:*",
        "ecr:*",
        "iam:*",
        "dynamodb:*",
        "sqs:*",
        "sns:*",
        "events:*",
        "logs:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
```

### GitHub Secrets:
- ✅ No secrets required (OIDC authentication)
- ✅ AWS credentials generated per workflow run
- ✅ Temporary credentials (expire after run)

## Monitoring Workflow

### View Logs:
```bash
# Real-time logs
GitHub → Actions → Deploy to Dev → <running workflow>

# Filter by job
└── terraform ➜ View logs
└── build-and-push ➜ View logs (per service)
└── deploy-lambda ➜ View logs
└── deploy-eks ➜ View logs
└── notify ➜ View logs
```

### Check Status:
```bash
# Via GitHub CLI
gh run list --workflow=deploy-dev.yml
gh run view <run-id>
gh run watch <run-id>
```

### Deployment History:
```bash
# All deployments to dev
GitHub → Actions → "Deploy to Dev" → Filter: All workflows

# Shows:
- Commit SHA that triggered deployment
- Duration
- Status (success/failure)
- Triggered by (auto/manual)
```

## Rollback Procedure

### Via GitHub Actions:
```bash
1. Go to GitHub → Actions → Deploy to Dev
2. Find successful previous deployment
3. Note the commit SHA
4. Go to Code → Commits
5. Revert commit: git revert <commit-sha>
6. Push to main → Auto-redeploy
```

### Manual Rollback:
```bash
# Lambda
aws lambda update-function-code \
  --function-name casestudy2-dev-parser \
  --zip-file fileb://parser-backup.zip

# EKS
kubectl rollout undo deployment/soar-api -n soar-system

# Terraform
git revert <commit-sha>
terraform apply
```

---

**Workflow File**: `.github/workflows/deploy-dev.yml`
**Status**: ✅ Active
**Last Updated**: October 8, 2025
