# VPN Setup Guide - Fontys Netlab to AWS Cloud

## Overview
This guide explains how to configure a Site-to-Site VPN connection between your **on-premises Fontys Netlab environment** (Apache server at 192.168.154.13) and the **AWS VPC** running the SOAR platform.

## Network Architecture
```
┌─────────────────────────────────────┐         ┌──────────────────────────────────────┐
│   On-Premises (Fontys Netlab)      │         │         AWS VPC (10.0.0.0/16)        │
│                                     │         │                                      │
│  ┌──────────────────────────┐      │         │  ┌────────────────────────────┐     │
│  │  Apache Web Server       │      │         │  │  SOAR API (EKS)            │     │
│  │  192.168.154.13          │      │ IPSec   │  │  10.0.1.x                  │     │
│  │  http://192.168.154.13   │◄─────┼─────────┼─►│                            │     │
│  └──────────────────────────┘      │ Tunnel  │  └────────────────────────────┘     │
│                                     │         │                                      │
│  Network: 192.168.154.0/24          │         │  ┌────────────────────────────┐     │
│  VPN via: Cisco AnyConnect           │         │  │  Lambda Functions          │     │
│  Public IP: [YOUR_PUBLIC_IP]        │         │  │  10.0.2.x (in VPC)         │     │
└─────────────────────────────────────┘         │  └────────────────────────────┘     │
                                                │                                      │
                                                │  ┌────────────────────────────┐     │
                                                │  │  DynamoDB, SQS, SNS        │     │
                                                │  │  (Managed Services)        │     │
                                                │  └────────────────────────────┘     │
                                                └──────────────────────────────────────┘
```

## Why Do We Need VPN?

Based on your network diagram and the Apache server at 192.168.154.13:
1. **Log Collection**: The SOAR platform needs to collect security logs/events from the on-premises Apache server
2. **Bidirectional Communication**: AWS Lambda and EKS services need to query/access the on-premises infrastructure
3. **Secure Connection**: VPN provides encrypted tunnel between on-premises and cloud

## Prerequisites

### 1. Get Your Public IP Address
The public IP of your Fontys Netlab gateway (where VPN traffic exits):

```powershell
# Option 1: Via PowerShell
Invoke-RestMethod -Uri "https://api.ipify.org"

# Option 2: Via website
# Visit: https://whatismyipaddress.com
```

**Note**: Since you're connected via Cisco AnyConnect VPN, you need the **Fontys network's public IP**, not your home IP.

### 2. Network Information
- **On-premises CIDR**: `192.168.154.0/24`
- **Apache Server**: `192.168.154.13:80`
- **AWS VPC CIDR**: `10.0.0.0/16` (configured in Terraform)

## Step 1: Configure Terraform Variables

Edit your Terraform configuration or create a `terraform.tfvars` file:

```hcl
# terraform/terraform.tfvars
enable_vpn       = true
onprem_public_ip = "YOUR_FONTYS_PUBLIC_IP_HERE"  # Replace with actual IP
onprem_cidr      = "192.168.154.0/24"
```

Or set via environment variables in GitHub Actions:

```yaml
# .github/workflows/deploy-dev.yml
env:
  TF_VAR_enable_vpn: "true"
  TF_VAR_onprem_public_ip: "${{ secrets.FONTYS_PUBLIC_IP }}"
```

## Step 2: Deploy VPN Infrastructure
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

## Step 4: Get VPN Configuration
After deployment, retrieve the VPN configuration:

```bash
# Get VPN tunnel endpoints
terraform output vpn_tunnel1_address
terraform output vpn_tunnel2_address

# Get pre-shared keys (sensitive)
terraform output -raw vpn_tunnel1_preshared_key
terraform output -raw vpn_tunnel2_preshared_key

# Get full configuration for your VPN device
terraform output -raw vpn_configuration > vpn-config.xml
```

## Step 5: Configure On-Premises VPN Device

### For Cisco ASA/Router
AWS provides a configuration template. Download it from:
- AWS Console → VPC → Site-to-Site VPN Connections → Download Configuration

Select your device:
- Vendor: Cisco
- Platform: ASA or IOS
- Software: Your version

### For pfSense/Generic IPSec
Use these parameters from Terraform outputs:

**Tunnel 1:**
- Remote Gateway: `<vpn_tunnel1_address>`
- Pre-Shared Key: `<vpn_tunnel1_preshared_key>`
- Local Network: `192.168.154.0/24`
- Remote Network: `10.0.0.0/16`
- Phase 1: IKEv2, AES-256, SHA-256, DH Group 14
- Phase 2: AES-256, SHA-256, DH Group 14

**Tunnel 2:** (same as Tunnel 1 but with tunnel2 addresses)

## Step 6: Test Connectivity

### From On-Premises to AWS
```bash
# Ping a private IP in AWS (e.g., Lambda ENI)
ping <aws-private-ip>

# Test connection to EKS API
curl -k https://<eks-private-endpoint>
```

### From AWS to On-Premises
```bash
# SSH into an EC2 instance in the VPC, then:
ping 192.168.154.13

# Test Apache server
curl http://192.168.154.13
```

## Step 7: Update Security Groups
Add the VPN security group to resources that need on-premises access:

```hcl
# Example: Lambda function
resource "aws_lambda_function" "example" {
  vpc_config {
    subnet_ids         = aws_subnet.private[*].id
    security_group_ids = [
      aws_security_group.lambda.id,
      aws_security_group.vpn.id  # Add this
    ]
  }
}
```

## Monitoring

### Check VPN Tunnel Status
```bash
# Via AWS CLI
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <vpn-connection-id>

# Check tunnel status
aws ec2 describe-vpn-connections \
  --vpn-connection-ids <vpn-connection-id> \
  --query 'VpnConnections[0].VgwTelemetry'
```

### CloudWatch Metrics
Monitor these metrics:
- `TunnelState`: UP or DOWN
- `TunnelDataIn`: Bytes received
- `TunnelDataOut`: Bytes transmitted

## Troubleshooting

### Tunnel Not Connecting
1. **Verify public IP** is correct in Customer Gateway
2. **Check firewall rules** allow UDP 500 (IKE) and UDP 4500 (NAT-T)
3. **Verify pre-shared keys** match on both sides
4. **Check Phase 1/2 proposals** match AWS requirements

### Can't Ping Across Tunnel
1. **Verify route propagation** in AWS route tables
2. **Check security groups** allow traffic from 192.168.154.0/24
3. **Verify on-premises routes** to 10.0.0.0/16 via VPN
4. **Check NACLs** in AWS VPC

### Tunnel Flapping
1. **Check for DPD (Dead Peer Detection)** mismatches
2. **Verify MTU settings** (recommend 1400 for VPN)
3. **Check for NAT** between on-premises device and internet

## Advanced Configuration

### High Availability
Both tunnels are active. Configure your on-premises device to:
- Use both tunnels in active/active mode (ECMP)
- Or use tunnel 2 as backup

### BGP Routing (Optional)
If you want dynamic routing instead of static:

```hcl
resource "aws_vpn_connection" "main" {
  # ... other config ...
  static_routes_only = false  # Enable BGP
}
```

Configure BGP on your on-premises device with ASN 65000.

## Cost Considerations
- VPN Connection: ~$0.05 per hour (~$36/month)
- Data Transfer: $0.09 per GB (first 10 TB)
- No charge for data into AWS

## Security Best Practices
1. **Rotate pre-shared keys** regularly
2. **Use strong encryption** (AES-256)
3. **Monitor tunnel logs** for anomalies
4. **Restrict traffic** with security groups (only needed protocols)
5. **Enable CloudWatch alarms** for tunnel down events

## Next Steps
After VPN is established:
1. Test connectivity from on-premises Apache (192.168.154.13) to AWS
2. Configure SOAR platform to collect logs from on-premises
3. Set up monitoring for VPN tunnel health
4. Document your specific on-premises VPN device configuration

## Support
- AWS VPN Documentation: https://docs.aws.amazon.com/vpn/
- Cisco VPN Configuration: https://www.cisco.com/c/en/us/support/security/asa-5500-series-next-generation-firewalls/products-installation-and-configuration-guides-list.html
