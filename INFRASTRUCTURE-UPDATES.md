# Infrastructure Updates Summary

## Date: October 8, 2025

## Problem Resolution
Previous destroy operations were failing due to:
- **ALB (Application Load Balancer)** not being deleted before ENIs
- **Network Interfaces (ENIs)** remaining attached and blocking subnet deletion
- **Elastic IPs** still mapped to VPC, preventing Internet Gateway detachment

## Changes Made

### 1. VPC Architecture Updates (`vpc.tf`)
- ✅ **Added dedicated Lambda subnets** (10.0.20.0/24, 10.0.21.0/24)
  - Separated from EKS private subnets for better isolation
  - Lambda functions now use their own subnet space
- ✅ **Added Lambda route tables**
  - Each Lambda subnet has its own route table with NAT Gateway
  - Enables Lambda to reach internet via NAT for external API calls (firewall API)

### 2. VPC Endpoints (`vpc_endpoints.tf` - NEW FILE)
- ✅ **Gateway Endpoints** (no cost, better performance):
  - S3 - for Lambda code, CloudWatch Logs
  - DynamoDB - for internal database access
- ✅ **Interface Endpoints** (cost-effective for internal traffic):
  - SQS - Lambda to SQS communication stays internal
  - SNS - notification service
  - CloudWatch Logs - logging stays internal
  - Lambda - cross-Lambda invocations
  - ECR API & DKR - container image pulls
  - EKS - Kubernetes API access
  - EC2 - for EKS node management
  - STS - IAM role assumptions
  - Route53 - DNS resolution
- ✅ All endpoints attached to both private and Lambda subnets
- ✅ Private DNS enabled for seamless service access

### 3. Route53 DNS (`route53.tf` - NEW FILE)
- ✅ **Private Hosted Zone**: casestudy2-dev.internal
- ✅ **DNS Records**:
  - monitoring.casestudy2-dev.internal → Monitoring service IP
  - api.casestudy2-dev.internal → ALB (alias)
  - onprem.casestudy2-dev.internal → 192.168.154.13
- ✅ **Route53 Resolver** (optional):
  - Outbound endpoint for on-premises DNS forwarding
  - Resolver rules for Fontys domain (fontysict.nl)
- ✅ **VPC Endpoint** for Route53 resolver

### 4. Client VPN (`client_vpn.tf` - NEW FILE)
- ✅ **AWS Client VPN Endpoint** for remote access
  - Certificate-based authentication (mutual TLS)
  - Split tunnel enabled (only VPC traffic)
  - CIDR: 172.16.0.0/22 for VPN clients
- ✅ **Network associations** to public subnets
- ✅ **Authorization rules** for VPC and monitoring access
- ✅ **Security group** allowing monitoring ports (3000, 9090, 80, 443)
- ✅ **Self-signed certificates** (TLS for server and client)
- ✅ **CloudWatch logging** for VPN connections
- ✅ Allows YOU to connect to AWS for Grafana/Prometheus access

### 5. EventBridge Integration (`eventbridge.tf` - NEW FILE)
- ✅ **EventBridge rule** to capture events from on-premises webserver
  - Source: `custom.onprem`
  - Event types: Security Event, System Alert
- ✅ **API Destination** configured for on-premises webserver (192.168.154.13)
  - HTTP POST endpoint
  - Basic authentication support
- ✅ **EventBridge → SQS → Lambda** pipeline
  - Events forwarded to Parser Queue
  - Input transformation for consistent format
  - SQS queue policy allows EventBridge access

### 6. VPN Updates (`vpn.tf`)
- ✅ **Route propagation added for Lambda subnets**
  - Lambda can now reach on-premises network (192.168.154.0/24)
  - VPN routes propagated to Lambda route tables
- ✅ **Site-to-Site VPN** for on-premises webserver connectivity

### 7. Lambda Configuration (`lambda.tf`)
- ✅ **All Lambda functions moved to dedicated Lambda subnets**
  - Parser, Engine, Notify, Remediate
  - Better network isolation
  - Independent scaling and management

### 8. Security Groups (`security_groups.tf`)
- ✅ **EKS nodes security group** updated:
  - Allow Grafana (3000) from Client VPN CIDR
  - Allow Prometheus (9090) from Client VPN CIDR
  - Allow HTTP (80) from Client VPN CIDR
- ✅ Enables monitoring access via Client VPN

### 9. Destroy Workflow Enhancement (`.github/workflows/destroy-dev.yml`)
- ✅ **New ALB cleanup step** added before Terraform destroy:
  1. Find VPC by name tag
  2. Delete all ALBs in the VPC
  3. Wait 2 minutes for ALB deletion
  4. Delete all Target Groups
  5. Force detach and delete ENIs
  6. Disassociate and release Elastic IPs
- ✅ **Prevents dependency errors** during destroy
- ✅ Uses `continue-on-error: true` to handle missing resources gracefully

### 10. Variables Added (`variables.tf`)
- ✅ `onprem_webserver_ip` = 192.168.154.13
- ✅ `onprem_webserver_username` (sensitive)
- ✅ `onprem_webserver_password` (sensitive)
- ✅ `monitoring_service_ip` = 10.0.0.100
- ✅ `onprem_dns_ip` (optional, for DNS forwarding)
- ✅ `onprem_dns_domain` = fontysict.nl
- ✅ `enable_client_vpn` = true
- ✅ `client_vpn_cidr` = 172.16.0.0/22

### 11. Documentation
- ✅ `VPN-DNS-SETUP.md` - Complete VPN and DNS setup guide
- ✅ `INFRASTRUCTURE-UPDATES.md` - This file

## Network Architecture (According to Diagram)

### Two VPN Connections
1. **Site-to-Site VPN** (On-Premises Webserver → AWS)
   - Purpose: Connect on-premises webserver to AWS
   - Network: 192.168.154.0/24
   - Webserver: 192.168.154.13 (HTTP)
   - Authentication: IPsec pre-shared keys

2. **Client VPN** (Your Laptop → AWS Monitoring)
   - Purpose: Remote access to monitoring services
   - CIDR: 172.16.0.0/22
   - Authentication: Certificate-based (mutual TLS)
   - Access: Grafana, Prometheus via DNS

### Flow 1: On-Premises → Cloud
```
On-Premises Webserver (192.168.154.13)
    ↓ (HTTP)
Site-to-Site VPN (145.93.176.197)
    ↓
VPN Gateway in VPC
    ↓
EventBridge (captures events)
    ↓
SQS Parser Queue
    ↓
Lambda Parser (in Lambda subnet)
    ↓ (via VPC endpoints - internal)
DynamoDB + Engine Queue
```

### Flow 2: You → Monitoring
```
Your Laptop
    ↓ AWS VPN Client
Client VPN Endpoint (172.16.0.x)
    ↓
VPC Public Subnet
    ↓
Route53 DNS: monitoring.casestudy2-dev.internal
    ↓
EKS Pod (Grafana:3000 or Prometheus:9090)
```

### Flow 3: ALB → Lambda
```
Internet
    ↓
ALB (in public subnets)
    ↓
EKS Pods (in private subnets)
    ↓ (via NAT Gateway for firewall API)
External Firewall API
    ↓
SQS Queues (via VPC endpoints)
    ↓
Lambda Functions (in Lambda subnets)
```

### Flow 4: Pods → External (via NAT Gateway)
```
EKS Pods (private subnets)
    ↓
NAT Gateway (public subnets)
    ↓
Internet Gateway
    ↓
External Firewall API
```

### Flow 5: Lambda → AWS Services (Internal)
```
Lambda (Lambda subnet)
    ↓ (NO NAT)
VPC Endpoints (SQS, DynamoDB, SNS, etc.)
    ↓ (Internal AWS network)
AWS Services
```

## VPN Configuration
**Connection Details:**
- VPN Server: vpn.netlab.fontysict.nl
- Group: Netlab Fontys ICT
- Username: I546927
- On-premises network: 192.168.154.0/24
- On-premises webserver: 192.168.154.13 (HTTP)

**Terraform VPN:**
- Customer Gateway: 145.93.176.197 (Fontys public IP)
- Virtual Private Gateway attached to VPC
- Static routes to 192.168.154.0/24
- Route propagation to private and Lambda subnets

## Cost Optimization
- **VPC Endpoints** reduce NAT Gateway data transfer costs
- **Gateway endpoints** (S3, DynamoDB) are free
- **Interface endpoints** have hourly cost but save on data transfer
- Lambda functions use VPC endpoints for AWS service calls (no NAT needed)

## Testing Checklist
- [ ] Verify Lambda functions can reach on-premises (192.168.154.13) via VPN
- [ ] Test EventBridge → SQS → Lambda pipeline
- [ ] Confirm pods can reach firewall API via NAT Gateway
- [ ] Validate VPC endpoint connectivity (SQS, DynamoDB, SNS)
- [ ] Test destroy workflow (should complete without ALB/ENI errors)
- [ ] Verify monitoring via Prometheus/Grafana (separate VPN)

## Next Steps
1. Commit and push changes
2. Run GitHub Actions deploy workflow
3. Test VPN connectivity to on-premises
4. Validate EventBridge event flow
5. Test destroy workflow to ensure clean teardown

## Notes
- **Two VPNs**: Site-to-Site VPN for on-premises webserver, separate VPN for monitoring
- **NAT Gateway**: Required for pods to reach external firewall API
- **VPC Endpoints**: Internal communication to AWS services (no internet)
- **ALB**: Must be deleted manually before Terraform destroy (now automated)
