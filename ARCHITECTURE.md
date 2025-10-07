# Case Study 2 - SOAR Platform Architecture

## Network Architecture

Based on the provided network diagram, the infrastructure consists of:

### AWS Cloud Infrastructure

#### VPC Architecture (10.0.0.0/16)
- **2 Availability Zones** for high availability
- **Public Subnets** (10.0.0.0/24, 10.0.1.0/24)
  - Internet Gateway for public access
  - NAT Gateways for private subnet egress
  - Application Load Balancer
- **Private Subnets** (10.0.10.0/24, 10.0.11.0/24)
  - Lambda Functions (Parser, Engine, Notify, Remediate)
  - EKS Worker Nodes
  - RDS PostgreSQL Database

#### Compute Services
- **Lambda Functions in VPC**
  - Parser Lambda: CloudTrail event parsing
  - Engine Lambda: Threat analysis and decision making
  - Notify Lambda: SNS notification handling
  - Remediate Lambda: Automated remediation execution
  
- **Amazon EKS Cluster**
  - SOAR API Service (REST API)
  - SOAR Processor Service (Event processing)
  - SOAR Remediation Service (Remediation worker)
  - Prometheus (Monitoring)
  - Grafana (Visualization)

#### Data Services
- **DynamoDB**: Event storage with GSI on severity
- **RDS PostgreSQL**: Persistent relational data
- **S3**: Terraform state and Lambda packages

#### Integration Services
- **EventBridge**: CloudTrail event routing
- **SQS Queues**: 
  - Parser Queue → Engine Queue
  - Remediation Queue
  - Notify Queue
- **SNS Topic**: Security alert notifications
- **Secrets Manager**: RDS credentials

#### Networking
- **Application Load Balancer**: SOAR API ingress
- **Security Groups**: Network-level security
- **VPC Endpoints**: Private AWS service access

## Event Flow

```
CloudTrail Events
    ↓
EventBridge Rule
    ↓
SQS Parser Queue
    ↓
Parser Lambda (VPC)
    ↓
DynamoDB + SQS Engine Queue
    ↓
Engine Lambda (VPC)
    ↓ (if threat detected)
    ├→ SQS Remediation Queue → Remediate Lambda (VPC)
    └→ SQS Notify Queue → Notify Lambda (VPC) → SNS Topic
```

## EKS Services

```
ALB → Ingress Controller
    ↓
SOAR API Pod (REST API)
    ↓
DynamoDB / RDS
    
SOAR Processor Pod → SQS → Event Processing
SOAR Remediation Pod → SQS → Remediation Actions
Prometheus + Grafana → Monitoring & Alerting
```

## Security Architecture

1. **Network Isolation**
   - Lambda functions in private subnets
   - No direct internet access
   - VPC endpoints for AWS services

2. **IAM Roles**
   - Separate roles for Lambda, EKS nodes, EC2
   - Least privilege principle
   - GitHub OIDC for CI/CD

3. **Encryption**
   - RDS encryption at rest
   - Secrets Manager for credentials
   - TLS for data in transit

4. **Monitoring**
   - CloudWatch Logs for all services
   - Prometheus metrics
   - Grafana dashboards
   - SNS alerts

## Deployment Strategy

1. **Infrastructure as Code**
   - Terraform for AWS resources
   - Kubernetes manifests for EKS workloads

2. **CI/CD Pipeline**
   - GitHub Actions with OIDC authentication
   - Automated testing and deployment
   - Separate dev/prod environments

3. **Monitoring & Alerting**
   - Prometheus for metrics collection
   - Grafana for visualization
   - CloudWatch for logs aggregation
   - SNS for critical alerts

## Scalability

- **Horizontal Scaling**
  - EKS Auto Scaling Groups
  - Lambda concurrent executions
  - DynamoDB auto-scaling

- **High Availability**
  - Multi-AZ deployment
  - RDS Multi-AZ standby
  - ALB health checks

## Cost Optimization

- Lambda pay-per-use
- DynamoDB on-demand billing
- EKS right-sized instances
- CloudWatch log retention policies
