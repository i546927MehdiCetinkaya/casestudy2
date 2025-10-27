# SOAR Security Platform# SOAR Security Platform - SSH Failed Login Monitoring# Case Study 2 - SOAR Security Platform



AWS-based Security Orchestration, Automation, and Response (SOAR) system that detects SSH failed login attempts and sends automated email alerts.



## ArchitectureSimple SOAR system that monitors SSH failed login attempts and sends email alerts.[![Deploy to Dev](https://github.com/i546927MehdiCetinkaya/casestudy2/actions/workflows/deploy-dev.yml/badge.svg)](https://github.com/i546927MehdiCetinkaya/casestudy2/actions/workflows/deploy-dev.yml)



```

Ubuntu Server → API Gateway → Ingress Lambda → SQS → Parser Lambda → DynamoDB

                                                   ↓## Architecture## 🎯 Project Overview

                                               Engine Lambda → Notify Lambda → SNS Email

```



## Components```This project implements a **Security Orchestration, Automation, and Response (SOAR)** platform on AWS using an event-driven architecture. The system automatically detects, analyzes, and remediates security threats in real-time.



### Lambda FunctionsUbuntu Server → API Gateway → Lambda Pipeline → Email Notifications

- **Ingress**: Receives events from API Gateway, validates, forwards to parser queue

- **Parser**: Stores events in DynamoDB, forwards to engine queue```### Architecture Components

- **Engine**: Analyzes failed login patterns, escalates severity, triggers notifications

- **Notify**: Sends email alerts via SNS at thresholds (3rd, 5th, 10th, 15th, 20th attempts)

- **Remediate**: Logs remediation events to DynamoDB

### Components- **VPC** with public/private subnets across 2 AZs

### AWS Services

- **API Gateway**: REST API endpoint with API key authentication- **Lambda Functions** (in VPC) for event processing:

- **DynamoDB**: Event storage (event_id, timestamp, user, IP, hostname, service)

- **SQS**: Asynchronous queuing (parser-queue, engine-queue, notify-queue, remediation-queue)- **API Gateway**: Receives failed login events from Ubuntu server  - Parser Lambda - Parses CloudTrail events

- **SNS**: Email notification system

- **CloudWatch**: Monitoring, logs, alarms, dashboard- **Lambda Functions**:  - Engine Lambda - Analyzes threats and determines actions

- **VPC**: Private networking for Lambda functions

- **VPN**: Site-to-site connection to on-premises network  - **Ingress**: Validates and forwards events  - Notify Lambda - Sends security alerts via SNS



## Deployment  - **Parser**: Stores events in DynamoDB  - Remediate Lambda - Executes automated remediation



### Prerequisites  - **Engine**: Counts attempts, escalates severity- **Amazon EKS** cluster for SOAR applications

- AWS Account with SSO configured

- Terraform installed  - **Notify**: Sends email alerts via SNS- **RDS PostgreSQL** for persistent storage

- AWS CLI configured

- **DynamoDB**: Stores security events- **DynamoDB** for event storage

### Deploy Infrastructure

```bash- **SQS**: Queues between Lambda functions- **SQS Queues** for asynchronous processing

cd terraform

terraform init- **SNS**: Email notifications- **SNS Topics** for notifications

terraform plan

terraform apply- **CloudWatch**: Monitoring and dashboards- **EventBridge** for event routing

```

- **Application Load Balancer** for API access

### Get API Credentials

```bash## Deployment- **Monitoring Stack** (Prometheus + Grafana)

terraform output api_gateway_endpoint

aws apigateway get-api-key --api-key <KEY_ID> --include-value --query 'value' --output text

```

### Prerequisites## 📁 Project Structure

## Ubuntu Server Setup



### 1. Copy monitor script to Ubuntu

```bash- AWS Account with SSO configured```

# Transfer scripts/ubuntu-monitor.sh to your Ubuntu server

scp scripts/ubuntu-monitor.sh user@ubuntu-server:~/- Terraform installedcasestudy2/

```

- Valid AWS credentials├── terraform/              # Infrastructure as Code

### 2. Edit script with your API key

```bash│   ├── main.tf            # Main Terraform configuration

nano ubuntu-monitor.sh

# Replace API_KEY with your actual key### Deploy│   ├── vpc.tf             # VPC and networking

```

│   ├── eks.tf             # EKS cluster

### 3. Run the monitor

```bash```bash│   ├── lambda.tf          # Lambda functions

chmod +x ubuntu-monitor.sh

sudo ./ubuntu-monitor.shcd terraform│   ├── rds.tf             # RDS database

```

terraform init│   ├── services.tf        # DynamoDB, SQS, SNS, EventBridge

### 4. Test with failed logins

```bashterraform apply│   ├── alb.tf             # Application Load Balancer

# From another terminal

ssh wronguser@localhost```│   ├── ecr.tf             # Container registry

# Enter wrong password 5 times to trigger notifications

```│   ├── security_groups.tf # Security groups



## Email Notifications### Get API Endpoint│   ├── variables.tf       # Input variables



Configure SNS subscription:│   └── outputs.tf         # Output values

1. Check email (mehdicetinkaya6132@gmail.com) for confirmation

2. Click confirmation link```bash├── lambda/                # Lambda function code

3. Receive alerts at: 3rd, 5th, 10th, 15th, 20th failed attempt within 2 minutes

terraform output api_gateway_endpoint│   ├── parser/            # Event parser

## Monitoring

terraform output api_key│   ├── engine/            # Threat analysis engine

- **CloudWatch Dashboard**: casestudy2-dev-soar-monitoring

- **Lambda Logs**: /aws/lambda/casestudy2-dev-*```│   ├── notify/            # Notification service

- **DynamoDB Table**: casestudy2-dev-events

│   └── remediate/         # Remediation service

## Project Structure

## Monitoring├── kubernetes/            # Kubernetes manifests

```

casestudy2/│   ├── namespace.yaml

├── lambda/

│   ├── ingress/### Email Alerts│   ├── soar-api-deployment.yaml

│   ├── parser/

│   ├── engine/│   ├── soar-processor-deployment.yaml

│   ├── notify/

│   └── remediate/Notifications sent at: 3rd, 5th, 10th, 15th, 20th failed attempt within 2 minutes│   ├── soar-remediation-deployment.yaml

├── terraform/

│   ├── main.tf│   ├── ingress.yaml

│   ├── vpc.tf

│   ├── lambda.tf### CloudWatch Dashboard│   ├── prometheus.yaml

│   ├── api_gateway.tf

│   ├── services.tf (DynamoDB, SQS, SNS)│   └── grafana.yaml

│   └── outputs.tf

├── scripts/Dashboard: `casestudy2-dev-soar-monitoring`├── docker/                # Docker images

│   ├── package-lambdas.ps1

│   ├── refresh-aws-credentials.ps1│   ├── soar-api/

│   └── ubuntu-monitor.sh

└── .github/workflows/## Project Structure│   ├── soar-processor/

    ├── deploy.yml

    ├── destroy.yml│   └── soar-remediation/

    └── terraform-plan.yml

``````├── ansible/               # Ansible playbooks



## Development├── lambda/│   ├── configure-eks.yml



### Package Lambda Functions│   ├── ingress/       # API Gateway handler│   └── deploy-lambda.yml

```powershell

cd scripts│   ├── parser/        # Event storage└── .github/workflows/     # CI/CD pipelines

.\package-lambdas.ps1

```│   ├── engine/        # Threat analysis    ├── deploy-dev.yml



### Refresh AWS Credentials│   ├── notify/        # Email notifications    └── terraform-plan.yml

```powershell

.\refresh-aws-credentials.ps1│   └── remediate/     # Event logging```

```

└── terraform/         # Infrastructure code

## Cleanup

```## 🚀 Deployment Instructions

To destroy all resources:

```bash

cd terraform

terraform destroy## Ubuntu Setup### Prerequisites

```



Or use GitHub Actions workflow "Destroy Lambda SOAR" with confirmation.

The Ubuntu server sends failed SSH login events to API Gateway. No credentials needed - just API key authentication.1. **AWS Account** with appropriate permissions

---

2. **GitHub Repository** with OIDC configured

**Project**: Case Study 2 - SOAR Security Platform  

**University**: Fontys University of Applied Sciences  ---3. **AWS CLI** installed and configured

**Semester**: 3  

**Student**: Mehdi Cetinkaya4. **Terraform** v1.6+ installed


**Simple, functional SOAR monitoring system**5. **kubectl** installed

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