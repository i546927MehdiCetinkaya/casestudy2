# VPN & DNS Setup Guide

## Overview
This project uses **TWO separate VPN connections**:
1. **Site-to-Site VPN** - Connects on-premises webserver to AWS VPC
2. **Client VPN** - Allows you to connect to AWS for monitoring access

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                         AWS VPC (10.0.0.0/16)                        │
│                                                                       │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │   Public     │    │   Private    │    │   Lambda     │          │
│  │   Subnets    │    │   Subnets    │    │   Subnets    │          │
│  │ (EKS, ALB)   │    │ (EKS Pods)   │    │ (Functions)  │          │
│  └──────────────┘    └──────────────┘    └──────────────┘          │
│         │                    │                    │                  │
│         │                    │                    │                  │
│    ┌────▼────────────────────▼────────────────────▼────┐            │
│    │            VPC Endpoints (Internal)                │            │
│    │  S3, DynamoDB, SQS, SNS, CloudWatch, etc.         │            │
│    └───────────────────────────────────────────────────┘            │
│                                                                       │
│    ┌─────────────────────────────────────────────────────┐          │
│    │          Route53 Private Hosted Zone                │          │
│    │  - monitoring.casestudy2-dev.internal               │          │
│    │  - api.casestudy2-dev.internal                      │          │
│    │  - onprem.casestudy2-dev.internal (192.168.154.13)  │          │
│    └─────────────────────────────────────────────────────┘          │
│                                                                       │
└───────────┬─────────────────────────────────────────┬────────────────┘
            │                                         │
            │                                         │
    ┌───────▼────────┐                       ┌────────▼────────┐
    │  VPN Gateway   │                       │  Client VPN     │
    │  (Site-to-Site)│                       │  Endpoint       │
    └───────┬────────┘                       └────────┬────────┘
            │                                         │
            │                                         │
  ┌─────────▼─────────┐                   ┌───────────▼──────────┐
  │  On-Premises      │                   │  Your Laptop/PC      │
  │  Webserver        │                   │  (VPN Client)        │
  │  192.168.154.13   │                   │  172.16.0.0/22       │
  │                   │                   │                      │
  │  via Fontys VPN:  │                   │  AWS VPN Client      │
  │  vpn.netlab...    │                   │  - Grafana access    │
  │  Group: Netlab    │                   │  - Prometheus access │
  │  User: I546927    │                   │  - Internal DNS      │
  └───────────────────┘                   └──────────────────────┘
```

## 1. Site-to-Site VPN (On-Premises Webserver)

### Purpose
Connects the on-premises webserver (192.168.154.13) to AWS VPC so that:
- Webserver can send security events to AWS via EventBridge
- Lambda functions can reach the webserver if needed
- Traffic flows: **Webserver → VPN → EventBridge → SQS → Lambda**

### Configuration
- **On-premises network**: 192.168.154.0/24
- **On-premises webserver**: 192.168.154.13 (HTTP)
- **Customer Gateway IP**: 145.93.176.197 (Fontys public IP)
- **VPN Type**: IPsec Site-to-Site
- **Routing**: Static routes

### Fontys VPN Access (Required for webserver)
```
Server: vpn.netlab.fontysict.nl
Group: Netlab Fontys ICT
Username: I546927
Password: 2004Mei3!!!
Network: 192.168.154.0/24
```

### Terraform Configuration
File: `terraform/vpn.tf`
- Creates Customer Gateway
- Creates Virtual Private Gateway
- Attaches VPN to VPC
- Propagates routes to private and Lambda subnets
- Static route to 192.168.154.0/24

### Testing Site-to-Site VPN
```bash
# Check VPN status
aws ec2 describe-vpn-connections --region eu-central-1

# From Lambda or EC2 in VPC, ping the webserver
ping 192.168.154.13

# Or use DNS
ping onprem.casestudy2-dev.internal
```

## 2. Client VPN (Your Access to Monitoring)

### Purpose
Allows YOU (and other authorized users) to connect to the AWS VPC to:
- Access Grafana dashboards via DNS
- Access Prometheus metrics
- Monitor the infrastructure
- Access internal services

### Configuration
- **Client VPN CIDR**: 172.16.0.0/22 (VPN client IP range)
- **Authentication**: Certificate-based (mutual TLS)
- **Split Tunnel**: Enabled (only VPC traffic goes through VPN)
- **DNS**: Uses VPC DNS resolver (10.0.0.2)

### Setup Steps

#### Step 1: Deploy Infrastructure
```bash
cd terraform
terraform init
terraform apply
```

#### Step 2: Download VPN Configuration
After deployment, get the Client VPN endpoint ID:
```bash
# Get endpoint ID
aws ec2 describe-client-vpn-endpoints --region eu-central-1

# Export configuration
aws ec2 export-client-vpn-client-configuration \
  --client-vpn-endpoint-id cvpn-endpoint-xxxxx \
  --output text > vpn-config.ovpn
```

#### Step 3: Get Client Certificate and Key
```bash
# Get outputs from Terraform
terraform output -raw client_vpn_client_certificate > client.crt
terraform output -raw client_vpn_client_key > client.key
```

#### Step 4: Add Certificate to Config
Edit `vpn-config.ovpn` and add at the end:
```
<cert>
[paste content of client.crt here]
</cert>

<key>
[paste content of client.key here]
</key>
```

#### Step 5: Install AWS VPN Client
Download from: https://aws.amazon.com/vpn/client-vpn-download/

#### Step 6: Import Configuration
1. Open AWS VPN Client
2. Click "File" → "Manage Profiles"
3. Click "Add Profile"
4. Select your `vpn-config.ovpn` file
5. Give it a name (e.g., "AWS Monitoring")
6. Click "Add Profile"

#### Step 7: Connect
1. Select the profile
2. Click "Connect"
3. Wait for connection to establish

#### Step 8: Access Monitoring
Once connected, access via DNS:
```
Grafana: http://monitoring.casestudy2-dev.internal:3000
Prometheus: http://monitoring.casestudy2-dev.internal:9090
API: http://api.casestudy2-dev.internal
```

## 3. DNS Configuration (Route53)

### Private Hosted Zone
- **Zone Name**: casestudy2-dev.internal
- **VPC**: Attached to main VPC
- **Purpose**: Internal DNS resolution for services

### DNS Records
1. **monitoring.casestudy2-dev.internal**
   - Points to monitoring service (Grafana/Prometheus)
   - Type: A record
   - IP: 10.0.0.100 (adjust as needed)

2. **api.casestudy2-dev.internal**
   - Points to ALB
   - Type: A record (alias to ALB)

3. **onprem.casestudy2-dev.internal**
   - Points to on-premises webserver
   - Type: A record
   - IP: 192.168.154.13

### DNS Resolution Flow
```
Pod/Lambda → Route53 Private Zone → Internal IP
          OR
Pod/Lambda → Route53 Resolver → On-premises DNS (if configured)
```

### VPC Endpoints for DNS
- **Route53 Resolver Endpoint**: Allows VPC to use Route53
- **Outbound Endpoint** (optional): Forwards queries to on-premises DNS

## 4. Security Groups

### EKS Nodes Security Group
Allows Client VPN access:
- Port 3000 (Grafana) from 172.16.0.0/22
- Port 9090 (Prometheus) from 172.16.0.0/22
- Port 80 (HTTP) from 172.16.0.0/22

### Lambda Security Group
- Full egress to internet (via NAT Gateway)
- Access to VPC endpoints (internal)
- Access to on-premises via VPN

### Client VPN Security Group
- Allows all traffic from VPN clients (172.16.0.0/22)
- Egress to VPC resources

## 5. Network Flow Examples

### Flow 1: On-Premises → AWS
```
Webserver (192.168.154.13)
  ↓ HTTP POST
Site-to-Site VPN (145.93.176.197)
  ↓ Encrypted tunnel
VPN Gateway in AWS VPC
  ↓
EventBridge (custom.onprem source)
  ↓
SQS Parser Queue
  ↓
Lambda Parser (via VPC endpoint)
  ↓
DynamoDB (via VPC endpoint)
```

### Flow 2: You → Monitoring
```
Your Laptop
  ↓ AWS VPN Client
Client VPN Endpoint (172.16.0.x assigned)
  ↓ Split tunnel
VPC Public Subnet
  ↓ Route to private subnet
Route53 DNS: monitoring.casestudy2-dev.internal → 10.0.0.100
  ↓
EKS Pod running Grafana (port 3000)
  ↓
Grafana Dashboard displayed
```

### Flow 3: Pod → External Firewall API
```
EKS Pod (private subnet)
  ↓
NAT Gateway (public subnet)
  ↓
Internet Gateway
  ↓
External Firewall API (HTTPS)
```

### Flow 4: Lambda → AWS Services (Internal)
```
Lambda (Lambda subnet)
  ↓ No NAT, uses VPC endpoints
SQS VPC Endpoint
  ↓ Internal AWS network
SQS Service
```

## 6. Cost Optimization

### VPC Endpoints
- **Gateway Endpoints** (S3, DynamoDB): **FREE**
- **Interface Endpoints**: ~$7.20/month each + data transfer
- **Savings**: Avoids NAT Gateway data transfer costs for AWS services

### NAT Gateway
- **Cost**: ~$32/month + $0.045/GB data transfer
- **Usage**: Only for external API calls (firewall API)
- **Pods use NAT**: Yes (for external calls)
- **Lambda uses VPC endpoints**: Yes (for AWS services)

### Client VPN
- **Cost**: ~$0.10/hour per connection + $0.05/GB data transfer
- **Usage**: Only when connected for monitoring

## 7. Troubleshooting

### Site-to-Site VPN Not Working
```bash
# Check VPN status
aws ec2 describe-vpn-connections --region eu-central-1

# Check route propagation
aws ec2 describe-route-tables --region eu-central-1 --filters "Name=vpc-id,Values=vpc-xxxxx"

# Check security groups
aws ec2 describe-security-groups --region eu-central-1 --filters "Name=vpc-id,Values=vpc-xxxxx"

# Test from Lambda
# Add test function that tries to reach 192.168.154.13
```

### Client VPN Not Connecting
- Check certificate is valid
- Verify Client VPN endpoint is active
- Check security group rules
- Verify subnet associations
- Check CloudWatch logs: `/aws/clientvpn/casestudy2-dev`

### DNS Not Resolving
```bash
# From inside VPC (EC2/Lambda):
nslookup monitoring.casestudy2-dev.internal
dig monitoring.casestudy2-dev.internal

# Check Route53 hosted zone
aws route53 list-hosted-zones
aws route53 list-resource-record-sets --hosted-zone-id Z***
```

### Cannot Access Monitoring
- Verify Client VPN is connected
- Check security group allows your VPN CIDR (172.16.0.0/22)
- Verify DNS resolves correctly
- Check Grafana/Prometheus pods are running: `kubectl get pods -n monitoring`

## 8. Next Steps After Deployment

1. **Test Site-to-Site VPN**
   - Connect to Fontys VPN
   - Access on-premises webserver
   - Verify events reach EventBridge

2. **Setup Client VPN**
   - Download configuration
   - Install AWS VPN Client
   - Connect and test monitoring access

3. **Verify DNS**
   - Test DNS resolution from pods
   - Test DNS resolution from Lambda
   - Test DNS resolution via Client VPN

4. **Monitor Costs**
   - Check VPC endpoint usage
   - Monitor NAT Gateway data transfer
   - Track Client VPN connection hours

## 9. Security Notes

- **Site-to-Site VPN**: Uses IPsec with pre-shared keys (generated by AWS)
- **Client VPN**: Uses mutual TLS authentication with self-signed certificates
- **Production**: Replace self-signed certificates with proper CA-signed certificates
- **Secrets**: Store VPN credentials in AWS Secrets Manager (future enhancement)
- **Access Control**: Add more granular authorization rules for Client VPN

## 10. Monitoring & Logging

### CloudWatch Logs
- **Client VPN**: `/aws/clientvpn/casestudy2-dev`
- **VPN Connections**: CloudWatch metrics for VPN tunnels
- **Route53**: Query logging (can be enabled)

### Metrics to Watch
- VPN tunnel status (up/down)
- Client VPN active connections
- DNS query count
- NAT Gateway data transfer
- VPC endpoint data transfer

---

**Created**: October 8, 2025
**Last Updated**: October 8, 2025
**Project**: Case Study 2 - SOAR Platform
**Contact**: I546927@student.fontys.nl
