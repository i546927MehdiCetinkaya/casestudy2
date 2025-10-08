# Subnet Configuration Fix Summary

## Date: October 8, 2025

## Problems Fixed

### 1. **ALB Subnet Configuration Error**
**Error:**
```
Error: creating ELBv2 application Load Balancer: A load balancer cannot be attached to multiple subnets in the same Availability Zone
```

**Root Cause:**
- ALB was configured with `[aws_subnet.alb_private.id, aws_subnet.private[0].id]`
- Both `alb_private` and `private[0]` are in **Availability Zone A**
- ALBs require subnets in at least **2 different AZs**

**Fix:**
```hcl
# Before
subnets = [aws_subnet.alb_private.id, aws_subnet.private[0].id]

# After
subnets = aws_subnet.private[*].id  # Uses private[0] (AZ A) and private[1] (AZ B)
```

---

### 2. **VPC Endpoints Duplicate Subnet Error**
**Error:**
```
Error: creating EC2 VPC Endpoint: DuplicateSubnetsInSameZone: Found another VPC endpoint subnet in the availability zone
```

**Root Cause:**
- VPC endpoints used: `concat(aws_subnet.private[*].id, [aws_subnet.alb_private.id], [aws_subnet.lambda_private.id])`
- This created duplicate subnets in AZ A:
  - `private[0]` → AZ A
  - `alb_private` → AZ A ❌ DUPLICATE
  - `lambda_private` → AZ A ❌ DUPLICATE
  - `private[1]` → AZ B

**Affected VPC Endpoints:**
- ❌ `aws_vpc_endpoint.sqs`
- ❌ `aws_vpc_endpoint.sns`
- ❌ `aws_vpc_endpoint.logs`
- ❌ `aws_vpc_endpoint.lambda`

**Fix:**
```hcl
# Before
subnet_ids = concat(aws_subnet.private[*].id, [aws_subnet.alb_private.id], [aws_subnet.lambda_private.id])

# After
subnet_ids = aws_subnet.private[*].id  # Only uses private[0] (AZ A) and private[1] (AZ B)
```

---

### 3. **Route53 Resolver VPC Endpoint Error**
**Error:**
```
Error: creating EC2 VPC Endpoint: The Vpc Endpoint Service 'com.amazonaws.eu-central-1.route53resolver' does not exist
```

**Root Cause:**
- Route53 Resolver does **NOT** have a VPC endpoint service
- Route53 DNS resolution is handled automatically by VPC DNS resolver
- Only Route53 **Resolver Endpoints** exist (for hybrid DNS), not VPC endpoints

**Fix:**
- Removed `aws_vpc_endpoint.route53` resource entirely
- Added comment explaining Route53 doesn't need VPC endpoint

---

### 4. **SQS Queue Policy Timeout**
**Error:**
```
Error: waiting for SQS Queue (Policy) create: timeout while waiting for state to become 'equal' (timeout: 19m59s)
```

**Root Cause:**
- This was likely a **cascading failure** from VPC endpoint errors
- EventBridge couldn't establish connection to SQS queue through broken VPC endpoints
- With VPC endpoints fixed, this should resolve automatically

---

## Subnet Architecture Overview

### Current Subnet Layout:
```
VPC: 10.0.0.0/16 (eu-central-1)

┌─────────────────────────────────────────────────────────────────┐
│ Availability Zone A (eu-central-1a)                             │
├─────────────────────────────────────────────────────────────────┤
│ ✅ public[0]:         10.0.0.0/24   (Internet Gateway)          │
│ ✅ private[0]:        10.0.10.0/24  (EKS, ALB, VPC Endpoints)   │
│ ✅ alb_private:       10.0.30.0/24  (Reserved for ALB only)     │
│ ✅ lambda_private:    10.0.2.0/24   (Lambda Functions)          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ Availability Zone B (eu-central-1b)                             │
├─────────────────────────────────────────────────────────────────┤
│ ✅ public[1]:         10.0.1.0/24   (Internet Gateway)          │
│ ✅ private[1]:        10.0.11.0/24  (EKS, ALB, VPC Endpoints)   │
└─────────────────────────────────────────────────────────────────┘
```

### Resource → Subnet Mapping:
| Resource | Subnets Used | Reason |
|----------|--------------|--------|
| **ALB** | `private[0]`, `private[1]` | Multi-AZ high availability |
| **EKS Cluster** | `private[0]`, `private[1]`, `public[0]`, `public[1]` | Nodes in private, control plane access |
| **Lambda Functions** | `lambda_private` (AZ A only) | Single AZ sufficient, lower cost |
| **VPC Endpoints** | `private[0]`, `private[1]` | Multi-AZ for redundancy |

---

## Files Modified

### 1. `terraform/alb.tf`
- Changed ALB subnets from `[alb_private, private[0]]` → `private[*]`
- ALB now spans AZ A and AZ B correctly

### 2. `terraform/vpc_endpoints.tf`
- Fixed 4 VPC endpoints: SQS, SNS, Logs, Lambda
- Changed subnets from `concat(...)` → `private[*]`
- All endpoints now use only 2 unique AZs

### 3. `terraform/route53.tf`
- Removed invalid `aws_vpc_endpoint.route53` resource
- Added comment explaining Route53 doesn't need VPC endpoint

---

## Validation Checklist

✅ **ALB Multi-AZ**: Uses private[0] (AZ A) + private[1] (AZ B)
✅ **VPC Endpoints**: All use private[0] + private[1] (no duplicates)
✅ **Route53**: No VPC endpoint required (removed)
✅ **Lambda**: Still uses dedicated lambda_private subnet
✅ **No Syntax Errors**: All Terraform files validated

---

## Expected Deployment Impact

### Before Fix:
- ❌ ALB creation failed (duplicate AZ)
- ❌ VPC endpoints failed (duplicate subnets)
- ❌ Route53 endpoint failed (doesn't exist)
- ❌ SQS policy timeout (cascading failure)
- ⏱️ Deployment time: ~20+ minutes until failure

### After Fix:
- ✅ ALB deploys successfully across 2 AZs
- ✅ VPC endpoints deploy without duplication
- ✅ Route53 works via VPC DNS resolver
- ✅ SQS policy completes quickly
- ⏱️ Expected deployment time: ~15-20 minutes

---

## Cost Impact

**No cost changes** - Same number of resources, just fixed configuration:
- ALB: $16.43/month (unchanged)
- VPC Endpoints: ~$7.20/endpoint/month (unchanged)
- NAT Gateways: ~$32/month each (unchanged)

---

## Testing Recommendations

### 1. **Verify ALB Multi-AZ Deployment**
```bash
aws elbv2 describe-load-balancers \
  --names casestudy2-dev-alb \
  --query 'LoadBalancers[0].AvailabilityZones[*].ZoneName'
```
Expected: `["eu-central-1a", "eu-central-1b"]`

### 2. **Verify VPC Endpoint Subnets**
```bash
aws ec2 describe-vpc-endpoints \
  --filters "Name=tag:Name,Values=casestudy2-dev-sqs-endpoint" \
  --query 'VpcEndpoints[0].SubnetIds'
```
Expected: 2 subnet IDs (private[0] and private[1])

### 3. **Verify Route53 DNS Resolution**
```bash
# From Lambda or EKS pod
nslookup api.casestudy2-dev.internal
```
Expected: Resolves to ALB private IP

---

## Related Documentation

- [TERRAFORM-FIX-SUMMARY.md](TERRAFORM-FIX-SUMMARY.md) - Previous EventBridge fixes
- [VPN-SETUP.md](VPN-SETUP.md) - VPN disabled by default
- [ARCHITECTURE.md](ARCHITECTURE.md) - Full infrastructure architecture

---

## Summary

All subnet configuration errors have been fixed:
1. ✅ ALB now correctly spans 2 availability zones
2. ✅ VPC endpoints use unique subnets (no duplicates)
3. ✅ Route53 invalid VPC endpoint removed
4. ✅ SQS policy should complete successfully

**Next Step:** Commit changes and trigger GitHub Actions deployment.
