# Architecture Update - ALB and Lambda in Private Subnet AZ A

## Date: October 8, 2025 (Update 2)

## Changes Made

### Subnet Architecture Restructure

#### Previous Architecture:
- Public Subnets (AZ A & B): ALB
- Private Subnets (AZ A & B): EKS Pods
- Lambda Subnets (AZ A & B): Lambda Functions

#### New Architecture (According to Diagram):
- **Public Subnets (AZ A & B)**: NAT Gateway, Internet Gateway access
- **Private Subnets (AZ A & B)**: EKS Pods (unchanged)
- **ALB Private Subnet (AZ A only)**: Internal ALB - 10.0.30.0/24
- **Lambda Private Subnet (AZ A only)**: Lambda Functions - 10.0.31.0/24

### Key Changes:

#### 1. ALB Moved to Private Subnet (`alb.tf`)
- **Changed**: `internal = true` (was `false`)
- **Subnet**: Now uses `aws_subnet.alb_private` (AZ A only)
- **Security Group**: Updated to allow traffic from VPC CIDR and Client VPN CIDR only
- **Result**: ALB is now internal and not publicly accessible

#### 2. Lambda Consolidated to AZ A (`lambda.tf`)
- **All Lambda functions** (Parser, Engine, Notify, Remediate) now use single subnet
- **Subnet**: `aws_subnet.lambda_private` (AZ A only)
- **Benefit**: Simplified network architecture, single AZ for Lambda

#### 3. New Subnets Added (`vpc.tf`)
```terraform
# ALB Private Subnet (AZ A)
- CIDR: 10.0.30.0/24
- AZ: eu-central-1a (first AZ)
- Route Table: Own route table with NAT Gateway

# Lambda Private Subnet (AZ A)
- CIDR: 10.0.31.0/24
- AZ: eu-central-1a (first AZ)
- Route Table: Own route table with NAT Gateway
```

#### 4. Route Tables Updated
- Created separate route tables for ALB and Lambda private subnets
- Both use NAT Gateway in AZ A for outbound internet access
- VPN routes propagated to both new subnets

#### 5. VPC Endpoints Updated (`vpc_endpoints.tf`)
- All interface endpoints now include ALB and Lambda private subnets
- Gateway endpoints (S3, DynamoDB) route tables updated
- Ensures internal AWS service communication works for all subnets

#### 6. Security Groups Updated (`security_groups.tf`)
- **ALB Security Group**:
  - Changed from public (`0.0.0.0/0`) to internal
  - Allows HTTP/HTTPS from VPC CIDR (`10.0.0.0/16`)
  - Allows HTTP/HTTPS from Client VPN CIDR (`172.16.0.0/22`)
  - Description updated to "Internal Application Load Balancer"

#### 7. VPN Route Propagation Updated (`vpn.tf`)
- Added route propagation to ALB private subnet route table
- Added route propagation to Lambda private subnet route table
- Ensures on-premises can reach ALB and Lambda if needed

## Network Topology

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                        │
│                                                                       │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │   Public Subnet      │        │   Public Subnet      │          │
│  │   AZ A (10.0.0.0/24) │        │   AZ B (10.0.1.0/24) │          │
│  │   - NAT Gateway      │        │   - NAT Gateway      │          │
│  │   - IGW              │        │   - IGW              │          │
│  └──────────────────────┘        └──────────────────────┘          │
│                                                                       │
│  ┌──────────────────────┐        ┌──────────────────────┐          │
│  │  Private Subnet      │        │  Private Subnet      │          │
│  │  AZ A (10.0.10.0/24) │        │  AZ B (10.0.11.0/24) │          │
│  │  - EKS Pods          │        │  - EKS Pods          │          │
│  └──────────────────────┘        └──────────────────────┘          │
│                                                                       │
│  ┌──────────────────────┐                                           │
│  │  ALB Private Subnet  │        ⚠️ NEW - AZ A Only                │
│  │  AZ A (10.0.30.0/24) │                                           │
│  │  - Internal ALB      │                                           │
│  └──────────────────────┘                                           │
│                                                                       │
│  ┌──────────────────────┐                                           │
│  │ Lambda Private Subnet│        ⚠️ NEW - AZ A Only                │
│  │  AZ A (10.0.31.0/24) │                                           │
│  │  - All Lambda Funcs  │                                           │
│  └──────────────────────┘                                           │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

## Traffic Flows

### Flow 1: Client VPN → Internal ALB → EKS Pods
```
Your Laptop (via Client VPN)
  ↓ 172.16.0.x
Client VPN Endpoint
  ↓
ALB Private Subnet (10.0.30.0/24)
  ↓
Internal ALB (HTTP/HTTPS)
  ↓
EKS Pods (Private Subnets 10.0.10.0/24, 10.0.11.0/24)
```

### Flow 2: On-Premises → EventBridge → SQS → Lambda
```
Webserver (192.168.154.13)
  ↓ Site-to-Site VPN
VPN Gateway
  ↓
EventBridge
  ↓
SQS Queue (via VPC endpoint)
  ↓
Lambda (10.0.31.0/24 - AZ A)
  ↓ VPC endpoints
DynamoDB, SNS (internal)
```

### Flow 3: Lambda → External Firewall API
```
Lambda (10.0.31.0/24)
  ↓
NAT Gateway (AZ A - 10.0.0.0/24)
  ↓
Internet Gateway
  ↓
External Firewall API (HTTPS)
```

### Flow 4: ALB → AWS Services (Internal)
```
ALB (10.0.30.0/24)
  ↓
VPC Endpoints (SQS, CloudWatch, etc.)
  ↓ Internal AWS network
AWS Services (no NAT charges)
```

## Cost Impact

### Removed:
- ❌ Lambda in AZ B (saves 1 subnet)
- ❌ Public ALB (no data transfer charges for internet traffic)

### Added:
- ✅ 2 new private subnets (ALB, Lambda in AZ A)
- ✅ Internal ALB (lower data transfer costs)
- ⚠️ Single AZ for Lambda (lower redundancy, but cost-efficient)

### Net Result:
- Slightly lower costs (internal ALB, no public internet traffic)
- Trade-off: Lower Lambda redundancy (single AZ vs multi-AZ)

## High Availability Considerations

### Maintained:
- ✅ EKS Pods: Still in 2 AZs (AZ A & B)
- ✅ NAT Gateways: Still in 2 AZs
- ✅ VPC Endpoints: Available in all subnets

### Changed:
- ⚠️ ALB: Now in single AZ (AZ A only)
- ⚠️ Lambda: Now in single AZ (AZ A only)

### Recommendations:
If high availability is critical for ALB and Lambda:
1. Add ALB subnet in AZ B (10.0.32.0/24)
2. Add Lambda subnet in AZ B (10.0.33.0/24)
3. Update ALB to use both subnets
4. Update Lambda functions to use both subnets

For now, keeping it simple with single AZ as per diagram.

## Security Improvements

### ALB Security:
- ✅ Internal only (not exposed to internet)
- ✅ Accessible only from VPC and Client VPN
- ✅ Defense in depth (private subnet + security group)

### Lambda Security:
- ✅ Isolated subnet (separate from EKS)
- ✅ VPC endpoints for AWS services (no internet)
- ✅ Controlled egress via NAT Gateway

## Testing Checklist

After deployment:
- [ ] Verify ALB is not publicly accessible
- [ ] Test ALB access via Client VPN
- [ ] Verify Lambda can reach SQS/DynamoDB via VPC endpoints
- [ ] Test Lambda egress to external firewall API
- [ ] Confirm VPN routes propagate correctly
- [ ] Test EKS pods can reach ALB
- [ ] Verify monitoring access via Client VPN

## Rollback Plan

If issues occur:
1. Change ALB `internal = false` and `subnets = aws_subnet.public[*].id`
2. Change Lambda `subnet_ids = aws_subnet.private[*].id`
3. Revert security group changes
4. Run `terraform apply`

---

**Updated**: October 8, 2025
**Status**: ✅ Ready for Deployment
**Architecture**: Matches provided network diagram
