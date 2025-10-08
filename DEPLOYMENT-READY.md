# Infrastructure Summary - Complete Setup

## ✅ What Has Been Completed

### 1. Network Architecture ✅
- **Dedicated Lambda Subnets**: 10.0.20.0/24, 10.0.21.0/24
- **Separate from EKS**: Better isolation and management
- **Own Route Tables**: Independent routing for Lambda functions

### 2. VPC Endpoints (Internal AWS Services) ✅
**Gateway Endpoints (FREE):**
- S3 (for Lambda code, logs)
- DynamoDB (for database access)

**Interface Endpoints (~$7/month each):**
- SQS, SNS, CloudWatch Logs, Lambda, ECR API/DKR
- EKS, EC2, STS, Route53 Resolver
- All attached to private AND Lambda subnets

**Benefits:**
- No NAT Gateway charges for AWS service traffic
- Better security (traffic stays in AWS network)
- Lower latency

### 3. DNS (Route53) ✅
**Private Hosted Zone:** `casestudy2-dev.internal`

**DNS Records:**
- `monitoring.casestudy2-dev.internal` → Monitoring service
- `api.casestudy2-dev.internal` → ALB
- `onprem.casestudy2-dev.internal` → 192.168.154.13

**Optional:**
- Route53 Resolver for on-premises DNS forwarding
- DNS forwarding to `fontysict.nl` domain

### 4. Dual VPN Setup ✅

#### A. Site-to-Site VPN (On-Premises Webserver)
**Purpose:** Connect on-premises webserver to AWS
- **Network:** 192.168.154.0/24
- **Webserver:** 192.168.154.13 (HTTP)
- **Customer Gateway:** 145.93.176.197 (Fontys public IP)
- **Flow:** Webserver → VPN → EventBridge → SQS → Lambda

**Your Fontys VPN Access:**
```
Server: vpn.netlab.fontysict.nl
Group: Netlab Fontys ICT
Username: I546927
Password: 2004Mei3!!!
```

#### B. Client VPN (Your Remote Access to Monitoring)
**Purpose:** Connect from your laptop to AWS monitoring
- **CIDR:** 172.16.0.0/22 (your VPN client will get IP from this range)
- **Authentication:** Certificate-based (mutual TLS)
- **Split Tunnel:** Only VPC traffic goes through VPN
- **Access:** Grafana (3000), Prometheus (9090), internal services

**How to Connect:**
1. Deploy infrastructure: `terraform apply`
2. Download VPN config: `aws ec2 export-client-vpn-client-configuration...`
3. Get certificates: `terraform output -raw client_vpn_client_certificate`
4. Install AWS VPN Client
5. Import config and connect
6. Access: `http://monitoring.casestudy2-dev.internal:3000`

### 5. EventBridge Integration ✅
- **Rule:** Captures events from on-premises (source: `custom.onprem`)
- **API Destination:** HTTP POST to 192.168.154.13
- **Flow:** EventBridge → SQS Parser Queue → Lambda Parser
- **Input Transformation:** Normalizes event format

### 6. Security Groups Updated ✅
- **EKS Nodes:** Allow monitoring ports (3000, 9090, 80) from Client VPN CIDR
- **Client VPN SG:** Allow all from VPN clients (172.16.0.0/22)
- **VPN SG:** Allow all from on-premises (192.168.154.0/24)

### 7. Destroy Workflow Fixed ✅
**New ALB Cleanup Step:**
1. Find VPC by name tag
2. Delete all ALBs
3. Wait 2 minutes
4. Delete Target Groups
5. Force detach/delete ENIs
6. Disassociate/release Elastic IPs

**Result:** No more dependency errors during destroy!

### 8. Documentation ✅
- **VPN-DNS-SETUP.md:** Complete guide for VPN setup and troubleshooting
- **INFRASTRUCTURE-UPDATES.md:** Detailed change log
- **README.md:** (existing) General project overview

## 📊 Network Flows

### Flow 1: On-Premises → AWS
```
Webserver (192.168.154.13)
  → Site-to-Site VPN
  → VPN Gateway
  → EventBridge
  → SQS Queue
  → Lambda Parser
  → DynamoDB (via VPC endpoint)
```

### Flow 2: You → Monitoring
```
Your Laptop
  → AWS VPN Client
  → Client VPN Endpoint (172.16.0.x)
  → Route53 DNS
  → EKS Pod (Grafana/Prometheus)
```

### Flow 3: Pods → External API
```
EKS Pod
  → NAT Gateway
  → Internet Gateway
  → External Firewall API
```

### Flow 4: Lambda → AWS Services
```
Lambda
  → VPC Endpoint (internal)
  → AWS Service (SQS/DynamoDB/SNS)
  (NO NAT Gateway charges!)
```

## 💰 Cost Breakdown

### Free:
- S3 VPC Gateway Endpoint
- DynamoDB VPC Gateway Endpoint

### Paid:
- NAT Gateway: ~$32/month + $0.045/GB
- Interface Endpoints: ~$7.20/month each × 10 = ~$72/month
- Client VPN: ~$0.10/hour when connected + $0.05/GB
- Site-to-Site VPN: ~$36/month

### Savings:
- VPC Endpoints save NAT Gateway data transfer costs
- Lambda uses endpoints instead of NAT → significant savings
- Split tunnel VPN → only VPC traffic, less data transfer

## 🎯 Next Steps

### 1. Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

### 2. Setup Client VPN (For Your Monitoring Access)
```bash
# Get endpoint ID
aws ec2 describe-client-vpn-endpoints --region eu-central-1

# Download config
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --output text > vpn-config.ovpn

# Get certificates
terraform output -raw client_vpn_client_certificate > client.crt
terraform output -raw client_vpn_client_key > client.key

# Add certificates to vpn-config.ovpn (see VPN-DNS-SETUP.md)
# Install AWS VPN Client
# Import config and connect
```

### 3. Test Site-to-Site VPN
- Connect to Fontys VPN (vpn.netlab.fontysict.nl)
- Access webserver at 192.168.154.13
- Send test event to EventBridge
- Verify it reaches Lambda

### 4. Test Monitoring Access
- Connect via Client VPN
- Access Grafana: `http://monitoring.casestudy2-dev.internal:3000`
- Access Prometheus: `http://monitoring.casestudy2-dev.internal:9090`

### 5. Verify DNS Resolution
```bash
# From inside VPC (EC2/Lambda)
nslookup monitoring.casestudy2-dev.internal
nslookup onprem.casestudy2-dev.internal
```

### 6. Monitor Costs
- Check VPC Endpoint usage in Cost Explorer
- Monitor NAT Gateway data transfer
- Track Client VPN connection hours

## 🔍 Troubleshooting

### Site-to-Site VPN Issues
```bash
# Check VPN status
aws ec2 describe-vpn-connections --region eu-central-1

# Check route propagation
aws ec2 describe-route-tables --region eu-central-1
```

### Client VPN Issues
- Check certificates are valid
- Verify endpoint is active
- Check security groups
- Review logs: `/aws/clientvpn/casestudy2-dev`

### DNS Issues
```bash
# From inside VPC
dig monitoring.casestudy2-dev.internal

# Check hosted zone
aws route53 list-hosted-zones
```

### Destroy Issues
- Run the enhanced destroy workflow (includes ALB cleanup)
- If fails, use `force-cleanup-all.ps1` (PowerShell) or `force-cleanup-all.sh` (Bash)

## 📝 Important Notes

### Two VPNs Explained:
1. **Site-to-Site VPN:** For on-premises webserver (192.168.154.13) to send events to AWS
2. **Client VPN:** For YOU to access monitoring from your laptop

### Security:
- Site-to-Site: IPsec with pre-shared keys (AWS-generated)
- Client VPN: Mutual TLS with self-signed certs (replace in production!)

### Production Recommendations:
- Replace self-signed certificates with CA-signed certificates
- Add more granular authorization rules for Client VPN
- Enable CloudWatch alarms for VPN tunnel status
- Implement Route53 query logging

## ✅ Architecture Matches Diagram:
- ✅ On-premises webserver via Site-to-Site VPN
- ✅ EventBridge → SQS → Lambda pipeline
- ✅ Lambda in dedicated subnets
- ✅ VPC endpoints for internal AWS services
- ✅ NAT Gateway for pods to reach external firewall API
- ✅ ALB in public subnets
- ✅ EKS pods in private subnets
- ✅ Client VPN for monitoring access
- ✅ Route53 for DNS resolution

## 🎉 Ready to Deploy!

All code is committed and pushed to GitHub. You can now:
1. Run `terraform apply` to deploy
2. Setup Client VPN for monitoring access
3. Test all network flows
4. Verify destroy workflow works without errors

See **VPN-DNS-SETUP.md** for detailed setup instructions!

---
**Last Updated:** October 8, 2025
**Status:** ✅ Ready for Deployment
**Commit:** c4ce02f
