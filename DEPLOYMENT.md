# SOAR Platform - Deployment Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [AWS Setup](#aws-setup)
3. [GitHub Configuration](#github-configuration)
4. [Initial Deployment](#initial-deployment)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- AWS CLI v2.x
- Terraform v1.6+
- kubectl v1.28+
- Docker v20+
- Python 3.11+
- Git

### AWS Account Requirements
- Account ID: 920120424621
- Region: eu-central-1
- IAM permissions for:
  - VPC, EC2, EKS
  - Lambda, DynamoDB, RDS
  - SQS, SNS, EventBridge
  - ECR, Secrets Manager
  - CloudWatch

## AWS Setup

### 1. Create OIDC Provider for GitHub

```bash
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --client-id-list sts.amazonaws.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 2. Create IAM Role for GitHub Actions

The role `arn:aws:iam::920120424621:role/githubrepo` should have:
- AdministratorAccess (for deployment)
- Trust relationship with GitHub OIDC

Trust Policy:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::920120424621:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:i546927MehdiCetinkaya/casestudy2:*"
        }
      }
    }
  ]
}
```

### 3. Create S3 Bucket for Terraform State

```bash
aws s3 mb s3://casestudy2-terraform-state --region eu-central-1

aws s3api put-bucket-versioning \
  --bucket casestudy2-terraform-state \
  --versioning-configuration Status=Enabled

aws s3api put-bucket-encryption \
  --bucket casestudy2-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'
```

## GitHub Configuration

### 1. Configure Repository Secrets

Go to: Settings → Secrets and variables → Actions

Add the following secrets:
- `DB_PASSWORD`: Secure password for RDS (minimum 8 characters)

### 2. Enable GitHub Actions

1. Go to Actions tab
2. Enable workflows
3. Workflows are in `.github/workflows/`

## Initial Deployment

### Option 1: Automatic (GitHub Actions)

1. Create and push to dev branch:
```bash
git checkout -b dev
git push origin dev
```

2. GitHub Actions will automatically:
   - Deploy infrastructure via Terraform
   - Build and push Docker images to ECR
   - Package and deploy Lambda functions
   - Deploy applications to EKS
   - Set up monitoring stack

3. Monitor deployment:
   - Go to Actions tab
   - Watch "Deploy to Dev" workflow

### Option 2: Manual Deployment

#### Step 1: Deploy Infrastructure

```bash
cd terraform

# Initialize Terraform
terraform init

# Review plan
terraform plan -var="db_password=YOUR_SECURE_PASSWORD"

# Apply infrastructure
terraform apply -var="db_password=YOUR_SECURE_PASSWORD" -auto-approve

# Save outputs
terraform output > ../outputs.txt
```

#### Step 2: Build and Push Docker Images

```bash
# Login to ECR
aws ecr get-login-password --region eu-central-1 | \
  docker login --username AWS --password-stdin \
  920120424621.dkr.ecr.eu-central-1.amazonaws.com

# Build and push soar-api
cd docker/soar-api
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-api:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-api:latest

# Build and push soar-processor
cd ../soar-processor
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-processor:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-processor:latest

# Build and push soar-remediation
cd ../soar-remediation
docker build -t 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-remediation:latest .
docker push 920120424621.dkr.ecr.eu-central-1.amazonaws.com/casestudy2/dev/soar-remediation:latest

cd ../..
```

#### Step 3: Deploy Lambda Functions

```bash
# Parser Lambda
cd lambda/parser
pip install -r requirements.txt -t .
zip -r parser.zip .
aws lambda update-function-code \
  --function-name casestudy2-dev-parser \
  --zip-file fileb://parser.zip \
  --region eu-central-1
cd ../..

# Engine Lambda
cd lambda/engine
pip install -r requirements.txt -t .
zip -r engine.zip .
aws lambda update-function-code \
  --function-name casestudy2-dev-engine \
  --zip-file fileb://engine.zip \
  --region eu-central-1
cd ../..

# Notify Lambda
cd lambda/notify
pip install -r requirements.txt -t .
zip -r notify.zip .
aws lambda update-function-code \
  --function-name casestudy2-dev-notify \
  --zip-file fileb://notify.zip \
  --region eu-central-1
cd ../..

# Remediate Lambda
cd lambda/remediate
pip install -r requirements.txt -t .
zip -r remediate.zip .
aws lambda update-function-code \
  --function-name casestudy2-dev-remediate \
  --zip-file fileb://remediate.zip \
  --region eu-central-1
cd ../..
```

#### Step 4: Deploy to EKS

```bash
# Update kubeconfig
aws eks update-kubeconfig --name casestudy2-dev-eks --region eu-central-1

# Get RDS endpoint
RDS_ENDPOINT=$(aws rds describe-db-instances \
  --db-instance-identifier casestudy2-dev-db \
  --query 'DBInstances[0].Endpoint.Address' \
  --output text)

# Create database secret
kubectl create secret generic db-credentials \
  --from-literal=host=$RDS_ENDPOINT \
  --from-literal=dbname=soardb \
  --from-literal=username=soaradmin \
  --from-literal=password=YOUR_DB_PASSWORD \
  -n soar-system --dry-run=client -o yaml | kubectl apply -f -

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

## Verification

### 1. Check Infrastructure

```bash
# Verify Terraform state
cd terraform
terraform show

# Check EKS cluster
aws eks describe-cluster --name casestudy2-dev-eks --region eu-central-1

# Check Lambda functions
aws lambda list-functions --region eu-central-1 | grep casestudy2

# Check DynamoDB table
aws dynamodb describe-table --table-name casestudy2-dev-events --region eu-central-1

# Check RDS instance
aws rds describe-db-instances --db-instance-identifier casestudy2-dev-db --region eu-central-1
```

### 2. Check Kubernetes Deployments

```bash
# Check namespaces
kubectl get namespaces

# Check deployments
kubectl get deployments -n soar-system
kubectl get deployments -n monitoring

# Check pods
kubectl get pods -n soar-system
kubectl get pods -n monitoring

# Check services
kubectl get svc -n soar-system
kubectl get svc -n monitoring

# Check ingress
kubectl get ingress -n soar-system
```

### 3. Test API

```bash
# Get ALB endpoint
ALB_DNS=$(kubectl get ingress soar-ingress -n soar-system -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test health endpoint
curl http://$ALB_DNS/health

# Test API endpoints
curl http://$ALB_DNS/api/events
curl http://$ALB_DNS/api/stats
```

### 4. Check Logs

```bash
# Lambda logs
aws logs tail /aws/lambda/casestudy2-dev-parser --follow

# Kubernetes logs
kubectl logs -f deployment/soar-api -n soar-system
kubectl logs -f deployment/soar-processor -n soar-system
```

### 5. Access Grafana

```bash
# Port forward to Grafana
kubectl port-forward svc/grafana 3000:80 -n monitoring

# Open browser to http://localhost:3000
# Default credentials: admin/admin
```

## Troubleshooting

### Lambda Functions Not Executing

1. Check VPC configuration:
```bash
aws lambda get-function-configuration --function-name casestudy2-dev-parser
```

2. Verify security groups allow outbound traffic
3. Check CloudWatch logs for errors

### EKS Pods Not Starting

1. Check pod status:
```bash
kubectl describe pod <POD_NAME> -n soar-system
```

2. Common issues:
   - Image pull errors: Check ECR permissions
   - Database connection: Verify security groups
   - Resource limits: Adjust memory/CPU requests

### RDS Connection Failed

1. Verify security group allows traffic from Lambda and EKS:
```bash
aws ec2 describe-security-groups --group-ids <RDS_SG_ID>
```

2. Test connection from EKS pod:
```bash
kubectl run -it --rm debug --image=postgres:15 --restart=Never -- \
  psql -h <RDS_ENDPOINT> -U soaradmin -d soardb
```

### DynamoDB Access Denied

1. Check IAM role policies
2. Verify Lambda execution role has DynamoDB permissions

### Docker Build Fails

1. Check Dockerfile syntax
2. Verify base image availability
3. Check network connectivity

## Post-Deployment

### Subscribe to SNS Alerts

```bash
aws sns subscribe \
  --topic-arn $(terraform output -raw sns_topic_arn) \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region eu-central-1
```

Confirm subscription via email.

### Enable CloudTrail (if not already enabled)

```bash
aws cloudtrail create-trail \
  --name casestudy2-security-trail \
  --s3-bucket-name casestudy2-cloudtrail-logs \
  --is-multi-region-trail \
  --region eu-central-1

aws cloudtrail start-logging \
  --name casestudy2-security-trail \
  --region eu-central-1
```

### Set Up CloudWatch Alarms

Monitor Lambda errors, EKS node health, RDS connections, etc.

## Cleanup

To destroy all resources:

```bash
# Delete Kubernetes resources
kubectl delete namespace soar-system
kubectl delete namespace monitoring

# Destroy Terraform infrastructure
cd terraform
terraform destroy -var="db_password=YOUR_PASSWORD" -auto-approve
```

## Support

For issues or questions:
- Check GitHub Issues
- Review CloudWatch Logs
- Consult AWS documentation
