# Case Study 2 - SOAR Security Platform

[![Deploy to Dev](https://github.com/i546927MehdiCetinkaya/casestudy2/actions/workflows/deploy-dev.yml/badge.svg)](https://github.com/i546927MehdiCetinkaya/casestudy2/actions/workflows/deploy-dev.yml)

## 🎯 Project Overview

This project implements a **Security Orchestration, Automation, and Response (SOAR)** platform on AWS using an event-driven architecture. The system automatically detects, analyzes, and remediates security threats in real-time.

### Architecture Components

- **VPC** with public/private subnets across 2 AZs
- **Lambda Functions** (in VPC) for event processing:
  - Parser Lambda - Parses CloudTrail events
  - Engine Lambda - Analyzes threats and determines actions
  - Notify Lambda - Sends security alerts via SNS
  - Remediate Lambda - Executes automated remediation
- **Amazon EKS** cluster for SOAR applications
- **RDS PostgreSQL** for persistent storage
- **DynamoDB** for event storage
- **SQS Queues** for asynchronous processing
- **SNS Topics** for notifications
- **EventBridge** for event routing
- **Application Load Balancer** for API access
- **Monitoring Stack** (Prometheus + Grafana)

## 📁 Project Structure

```
casestudy2/
├── terraform/              # Infrastructure as Code
│   ├── main.tf            # Main Terraform configuration
│   ├── vpc.tf             # VPC and networking
│   ├── eks.tf             # EKS cluster
│   ├── lambda.tf          # Lambda functions
│   ├── rds.tf             # RDS database
│   ├── services.tf        # DynamoDB, SQS, SNS, EventBridge
│   ├── alb.tf             # Application Load Balancer
│   ├── ecr.tf             # Container registry
│   ├── security_groups.tf # Security groups
│   ├── variables.tf       # Input variables
│   └── outputs.tf         # Output values
├── lambda/                # Lambda function code
│   ├── parser/            # Event parser
│   ├── engine/            # Threat analysis engine
│   ├── notify/            # Notification service
│   └── remediate/         # Remediation service
├── kubernetes/            # Kubernetes manifests
│   ├── namespace.yaml
│   ├── soar-api-deployment.yaml
│   ├── soar-processor-deployment.yaml
│   ├── soar-remediation-deployment.yaml
│   ├── ingress.yaml
│   ├── prometheus.yaml
│   └── grafana.yaml
├── docker/                # Docker images
│   ├── soar-api/
│   ├── soar-processor/
│   └── soar-remediation/
├── ansible/               # Ansible playbooks
│   ├── configure-eks.yml
│   └── deploy-lambda.yml
└── .github/workflows/     # CI/CD pipelines
    ├── deploy-dev.yml
    └── terraform-plan.yml
```

## 🚀 Deployment Instructions

### Prerequisites

1. **AWS Account** with appropriate permissions
2. **GitHub Repository** with OIDC configured
3. **AWS CLI** installed and configured
4. **Terraform** v1.6+ installed
5. **kubectl** installed
6. **Docker** installed (for local testing)

### Step 1: Configure GitHub Secrets

Add the following secrets to your GitHub repository:

```
DB_PASSWORD          # RDS database password
```

### Step 2: Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://casestudy2-terraform-state --region eu-central-1
aws s3api put-bucket-versioning \
  --bucket casestudy2-terraform-state \
  --versioning-configuration Status=Enabled
```

### Step 3: Deploy Infrastructure

#### Option A: Using GitHub Actions (Recommended)

1. Push code to `dev` branch:
```bash
git checkout -b dev
git add .
git commit -m "Initial deployment"
git push origin dev
```

2. The GitHub Actions workflow will automatically:
   - Deploy Terraform infrastructure
   - Build and push Docker images
   - Deploy Lambda functions
   - Deploy to EKS cluster

#### Option B: Manual Deployment

1. **Deploy Terraform Infrastructure:**

```bash
cd terraform
terraform init
terraform plan -var="db_password=YOUR_SECURE_PASSWORD"
terraform apply -var="db_password=YOUR_SECURE_PASSWORD"
```

2. **Build and Push Docker Images:**

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  920120424621.dkr.ecr.eu-central-1.amazonaws.com

# Build and push each service
cd docker/soar-api
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-api:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-api:latest

cd ../soar-processor
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-processor:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-processor:latest

cd ../soar-remediation
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-remediation:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-remediation:latest
```

3. **Package and Deploy Lambda Functions:**

```bash
cd lambda/parser
pip install -r requirements.txt -t .
zip -r parser.zip .
aws lambda update-function-code \
  --function-name casestudy2-dev-parser \
  --zip-file fileb://parser.zip

# Repeat for engine, notify, and remediate
```

4. **Deploy to EKS:**

```bash
# Update kubeconfig
aws eks update-kubeconfig --name casestudy2-dev-eks --region eu-central-1

# Deploy applications
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/soar-api-deployment.yaml
kubectl apply -f kubernetes/soar-processor-deployment.yaml
kubectl apply -f kubernetes/soar-remediation-deployment.yaml
kubectl apply -f kubernetes/ingress.yaml

# Deploy monitoring
kubectl apply -f kubernetes/prometheus.yaml
kubectl apply -f kubernetes/grafana.yaml
```

### Step 4: Verify Deployment

```bash
# Check EKS deployments
kubectl get deployments -n soar-system
kubectl get pods -n soar-system
kubectl get svc -n soar-system

# Check Lambda functions
aws lambda list-functions --region eu-central-1 | grep casestudy2

# Check ALB
aws elbv2 describe-load-balancers --region eu-central-1
```

## 🔧 Configuration

### Environment Variables

Lambda functions use the following environment variables:

- `ENVIRONMENT` - Environment name (dev/prod)
- `AWS_REGION` - AWS region
- `DYNAMODB_TABLE` - DynamoDB table name
- `SQS_QUEUE_URL` - SQS queue URL
- `SNS_TOPIC_ARN` - SNS topic ARN
- `RDS_SECRET_ARN` - RDS credentials secret ARN

### Kubernetes ConfigMaps and Secrets

Create database credentials secret:

```bash
kubectl create secret generic db-credentials \
  --from-literal=host=<RDS_ENDPOINT> \
  --from-literal=dbname=soardb \
  --from-literal=username=soaradmin \
  --from-literal=password=<YOUR_PASSWORD> \
  -n soar-system
```

## 📊 Monitoring and Logging

### Access Grafana

```bash
kubectl port-forward svc/grafana 3000:80 -n monitoring
```

Open http://localhost:3000 (credentials: admin/admin)

### View Lambda Logs

```bash
aws logs tail /aws/lambda/casestudy2-dev-parser --follow
```

### View EKS Pod Logs

```bash
kubectl logs -f deployment/soar-api -n soar-system
```

## 🔐 Security Features

- **VPC Isolation** - Lambda functions run in private subnets
- **Security Groups** - Strict ingress/egress rules
- **IAM Roles** - Least privilege access
- **Secrets Manager** - Encrypted credential storage
- **CloudWatch Logs** - Comprehensive logging
- **EventBridge** - Event-driven security monitoring

## 🧪 Testing

### Test Lambda Functions

```bash
# Invoke parser Lambda
aws lambda invoke \
  --function-name casestudy2-dev-parser \
  --payload '{"test": "event"}' \
  response.json
```

### Test API Endpoint

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress soar-ingress -n soar-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$ALB_DNS/health

# Get events
curl http://$ALB_DNS/api/events

# Get statistics
curl http://$ALB_DNS/api/stats
```

## 📈 Scaling

### Scale EKS Node Group

```bash
aws eks update-nodegroup-config \
  --cluster-name casestudy2-dev-eks \
  --nodegroup-name casestudy2-dev-node-group \
  --scaling-config minSize=2,maxSize=10,desiredSize=4
```

### Scale Kubernetes Deployments

```bash
kubectl scale deployment soar-api --replicas=5 -n soar-system
```

## 🛠️ Troubleshooting

### Common Issues

1. **Lambda timeout**: Increase timeout in `lambda.tf`
2. **EKS pods not starting**: Check IAM roles and security groups
3. **RDS connection failed**: Verify security group rules
4. **Docker build failed**: Check Dockerfile syntax

### Debug Commands

```bash
# Check Terraform state
terraform show

# Describe EKS cluster
aws eks describe-cluster --name casestudy2-dev-eks

# Get pod details
kubectl describe pod <POD_NAME> -n soar-system

# Check Lambda execution
aws lambda get-function --function-name casestudy2-dev-parser
```

## 🧹 Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace soar-system
kubectl delete namespace monitoring

# Destroy Terraform infrastructure
cd terraform
terraform destroy -var="db_password=YOUR_PASSWORD"
```

## 📚 Documentation

- [AWS Lambda Documentation](https://docs.aws.amazon.com/lambda/)
- [Amazon EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 👥 Contributors

- Mehdi Cetinkaya (@i546927MehdiCetinkaya)

## 📝 License

This project is for educational purposes - Case Study 2, Semester 3, Fontys University.

---

**Last Updated:** October 2025