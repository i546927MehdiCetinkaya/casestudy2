# Manual AWS Cleanup Guide

## Situation
Terraform destroy is stuck on subnet and security group deletion due to dependency issues.

## Step-by-Step Cleanup (via AWS Console)

### Step 1: Delete Lambda Functions
**Why:** Lambda ENIs in VPC subnets prevent subnet deletion

1. Go to: https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1#/functions
2. Filter by "casestudy2-dev"
3. Delete these functions:
   - `casestudy2-dev-parser`
   - `casestudy2-dev-engine`
   - `casestudy2-dev-notify`
   - `casestudy2-dev-remediate`
4. **Wait 5 minutes** for ENI cleanup

### Step 2: Delete EKS Cluster
**Why:** EKS creates ENIs and load balancers that block VPC deletion

1. Go to: https://eu-central-1.console.aws.amazon.com/eks/home?region=eu-central-1#/clusters
2. Find cluster: `casestudy2-dev-eks`
3. Delete cluster
4. **Wait 10-15 minutes** for full deletion

### Step 3: Delete Load Balancers
**Why:** ALB/NLB created by EKS or Terraform

1. Go to: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#LoadBalancers:
2. Filter by "casestudy2" or "dev"
3. Delete all matching load balancers
4. Go to Target Groups: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#TargetGroups:
5. Delete all matching target groups

### Step 4: Check and Delete Network Interfaces (ENIs)
**Why:** Orphaned ENIs prevent subnet deletion

1. Go to: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#NIC:
2. Filter by VPC: Look for "casestudy2-dev-vpc"
3. For each ENI:
   - If status = "available" → Delete immediately
   - If status = "in-use" → Note which resource is using it
4. Delete or detach all ENIs

### Step 5: Delete NAT Gateways
**Why:** NAT Gateways have ENIs that block subnet deletion

1. Go to: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#NatGateways:
2. Filter by "casestudy2"
3. Delete all NAT Gateways
4. **Wait 5 minutes** for full deletion

### Step 6: Release Elastic IPs
**Why:** EIPs associated with NAT Gateways need cleanup

1. Go to: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#Addresses:
2. Filter by "casestudy2"
3. Select and Release all unassociated Elastic IPs

### Step 7: Delete RDS Instances (if any)
**Why:** From the failed first deployment

1. Go to: https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#databases:
2. Look for "casestudy2-dev"
3. Delete database (uncheck "Create final snapshot" for faster deletion)
4. Delete DB Subnet Groups: https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1#db-subnet-groups-list:
5. Delete any "casestudy2-dev" subnet groups

### Step 8: Delete Security Groups
**Why:** Now that resources are gone, SGs can be deleted

1. Go to: https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1#SecurityGroups:
2. Filter by VPC or "casestudy2"
3. Delete in this order:
   - Lambda security groups
   - RDS security groups
   - EKS security groups
   - ALB security groups
   - Leave default VPC security group for last

### Step 9: Delete Subnets
**Why:** Now that ENIs and SGs are gone, subnets can be deleted

1. Go to: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#subnets:
2. Filter by "casestudy2"
3. Delete all private subnets
4. Delete all public subnets

### Step 10: Delete Route Tables
1. Go to: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#RouteTables:
2. Filter by "casestudy2"
3. Delete custom route tables (not main)

### Step 11: Delete Internet Gateway
1. Go to: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#igws:
2. Find "casestudy2-dev-igw"
3. Detach from VPC first
4. Then delete

### Step 12: Delete VPC
1. Go to: https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1#vpcs:
2. Find "casestudy2-dev-vpc"
3. Delete VPC

### Step 13: Delete Other Resources
**ECR Repositories:**
1. Go to: https://eu-central-1.console.aws.amazon.com/ecr/repositories?region=eu-central-1
2. Delete repositories starting with "casestudy2/dev/"

**DynamoDB Tables:**
1. Go to: https://eu-central-1.console.aws.amazon.com/dynamodbv2/home?region=eu-central-1#tables
2. Delete "casestudy2-dev-events"

**SQS Queues:**
1. Go to: https://eu-central-1.console.aws.amazon.com/sqs/v2/home?region=eu-central-1#/queues
2. Delete all "casestudy2-dev-*" queues

**SNS Topics:**
1. Go to: https://eu-central-1.console.aws.amazon.com/sns/v3/home?region=eu-central-1#/topics
2. Delete all "casestudy2-dev-*" topics

**EventBridge Rules:**
1. Go to: https://eu-central-1.console.aws.amazon.com/events/home?region=eu-central-1#/rules
2. Delete all "casestudy2-dev-*" rules

**Secrets Manager:**
1. Go to: https://eu-central-1.console.aws.amazon.com/secretsmanager/home?region=eu-central-1#!/listSecrets
2. Delete any "casestudy2-dev-*" secrets

**CloudWatch Log Groups:**
1. Go to: https://eu-central-1.console.aws.amazon.com/cloudwatch/home?region=eu-central-1#logsV2:log-groups
2. Delete all "/aws/lambda/casestudy2-dev-*" log groups
3. Delete "/aws/eks/casestudy2-dev-eks/*" log groups

### Step 14: Verify Terraform State
After manual cleanup, clean the Terraform state:

```powershell
cd terraform
terraform init
terraform refresh
terraform state list
```

If resources still show up in state but don't exist in AWS:
```powershell
# Remove individual resources from state
terraform state rm aws_vpc.main
terraform state rm aws_subnet.private[0]
# etc...
```

Or reset the state completely (CAREFUL!):
```powershell
# This will reset terraform state to empty
# terraform state rm $(terraform state list)
```

## Troubleshooting

### "Cannot delete subnet: has dependencies"
- Check for ENIs: EC2 → Network Interfaces
- Check for Lambda functions still in the subnet
- Check for RDS instances in the subnet

### "Cannot delete security group: in use"
- Check which resources reference it
- Look at the error message for resource IDs
- Delete those resources first

### "Cannot delete VPC: has dependencies"
- Make sure ALL resources in the VPC are deleted:
  - Subnets
  - Internet Gateways
  - NAT Gateways
  - VPN Gateways
  - Route Tables (except main)
  - Network ACLs (except default)
  - Security Groups (except default)
  - VPC Endpoints

## Quick Links
- **VPC Dashboard:** https://eu-central-1.console.aws.amazon.com/vpc/home?region=eu-central-1
- **EC2 Dashboard:** https://eu-central-1.console.aws.amazon.com/ec2/home?region=eu-central-1
- **Lambda Dashboard:** https://eu-central-1.console.aws.amazon.com/lambda/home?region=eu-central-1
- **EKS Dashboard:** https://eu-central-1.console.aws.amazon.com/eks/home?region=eu-central-1
- **RDS Dashboard:** https://eu-central-1.console.aws.amazon.com/rds/home?region=eu-central-1

## After Cleanup
Once everything is deleted manually, you can safely deploy again:

```powershell
git commit -m "feat: restore deploy workflow and add VPN configuration"
git push origin dev
```

The new deployment will:
- ✅ Use archive_file for Lambda (no more ZIP errors)
- ✅ No RDS (removed completely)
- ✅ Include VPN Site-to-Site for on-premises connectivity
