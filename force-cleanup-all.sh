#!/bin/bash
# Complete force cleanup script - removes everything manually

set +e  # Continue on errors

REGION="eu-central-1"
VPC_ID="vpc-091b0c91485383daa"
PROJECT="casestudy2"
ENV="dev"

echo "🔥 FORCE CLEANUP - Removing all resources manually"
echo "=================================================="

# 1. Delete EKS cluster (if exists)
echo "1️⃣ Checking EKS cluster..."
EKS_CLUSTER="${PROJECT}-${ENV}-eks"
aws eks describe-cluster --name "$EKS_CLUSTER" --region "$REGION" &>/dev/null
if [ $? -eq 0 ]; then
  echo "Deleting EKS node group..."
  NODE_GROUP=$(aws eks list-nodegroups --cluster-name "$EKS_CLUSTER" --region "$REGION" --query 'nodegroups[0]' --output text 2>/dev/null)
  if [ -n "$NODE_GROUP" ] && [ "$NODE_GROUP" != "None" ]; then
    aws eks delete-nodegroup --cluster-name "$EKS_CLUSTER" --nodegroup-name "$NODE_GROUP" --region "$REGION" 2>/dev/null
    echo "Waiting for node group deletion (this takes 5-10 min)..."
    aws eks wait nodegroup-deleted --cluster-name "$EKS_CLUSTER" --nodegroup-name "$NODE_GROUP" --region "$REGION" 2>/dev/null || true
  fi
  
  echo "Deleting EKS cluster..."
  aws eks delete-cluster --name "$EKS_CLUSTER" --region "$REGION" 2>/dev/null
  echo "Waiting for cluster deletion (this takes 5-10 min)..."
  aws eks wait cluster-deleted --name "$EKS_CLUSTER" --region "$REGION" 2>/dev/null || true
fi

# 2. Delete Lambda functions
echo "2️⃣ Deleting Lambda functions..."
LAMBDAS=$(aws lambda list-functions --region "$REGION" --query "Functions[?starts_with(FunctionName, '${PROJECT}-${ENV}')].FunctionName" --output text 2>/dev/null)
for FUNC in $LAMBDAS; do
  echo "  Deleting: $FUNC"
  aws lambda delete-function --function-name "$FUNC" --region "$REGION" 2>/dev/null || true
done

# 3. Wait for Lambda ENIs to be released
echo "3️⃣ Waiting 90 seconds for Lambda ENIs to be released..."
sleep 90

# 4. Delete NAT Gateways (they hold Elastic IPs)
echo "4️⃣ Deleting NAT Gateways..."
NAT_GWS=$(aws ec2 describe-nat-gateways --region "$REGION" --filter "Name=vpc-id,Values=$VPC_ID" "Name=state,Values=available" --query 'NatGateways[].NatGatewayId' --output text 2>/dev/null)
for NAT_GW in $NAT_GWS; do
  echo "  Deleting NAT Gateway: $NAT_GW"
  aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_GW" --region "$REGION" 2>/dev/null || true
done

if [ -n "$NAT_GWS" ]; then
  echo "  Waiting 3 minutes for NAT Gateways to be deleted..."
  sleep 180
fi

# 5. Release all Elastic IPs
echo "5️⃣ Releasing Elastic IPs..."
EIP_ALLOCS=$(aws ec2 describe-addresses --region "$REGION" --query 'Addresses[].AllocationId' --output text 2>/dev/null)
for ALLOC_ID in $EIP_ALLOCS; do
  echo "  Releasing EIP: $ALLOC_ID"
  aws ec2 release-address --allocation-id "$ALLOC_ID" --region "$REGION" 2>/dev/null || true
done

# 6. Delete all ENIs in VPC
echo "6️⃣ Force deleting ENIs..."
SUBNETS=$(aws ec2 describe-subnets --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[].SubnetId' --output text 2>/dev/null)
for SUBNET in $SUBNETS; do
  echo "  Checking subnet: $SUBNET"
  ENIS=$(aws ec2 describe-network-interfaces --region "$REGION" --filters "Name=subnet-id,Values=$SUBNET" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>/dev/null)
  for ENI in $ENIS; do
    echo "    Detaching ENI: $ENI"
    ATTACHMENT_ID=$(aws ec2 describe-network-interfaces --region "$REGION" --network-interface-ids "$ENI" --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>/dev/null)
    if [ -n "$ATTACHMENT_ID" ] && [ "$ATTACHMENT_ID" != "None" ]; then
      aws ec2 detach-network-interface --attachment-id "$ATTACHMENT_ID" --region "$REGION" --force 2>/dev/null || true
      sleep 5
    fi
    echo "    Deleting ENI: $ENI"
    aws ec2 delete-network-interface --network-interface-id "$ENI" --region "$REGION" 2>/dev/null || true
  done
done

# 7. Delete Load Balancers
echo "7️⃣ Deleting Load Balancers..."
ALBS=$(aws elbv2 describe-load-balancers --region "$REGION" --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text 2>/dev/null)
for ALB in $ALBS; do
  echo "  Deleting ALB: $ALB"
  aws elbv2 delete-load-balancer --load-balancer-arn "$ALB" --region "$REGION" 2>/dev/null || true
done

if [ -n "$ALBS" ]; then
  echo "  Waiting 60 seconds for ALBs to be deleted..."
  sleep 60
fi

# 8. Delete Target Groups
echo "8️⃣ Deleting Target Groups..."
TGS=$(aws elbv2 describe-target-groups --region "$REGION" --query "TargetGroups[?VpcId=='$VPC_ID'].TargetGroupArn" --output text 2>/dev/null)
for TG in $TGS; do
  echo "  Deleting TG: $TG"
  aws elbv2 delete-target-group --target-group-arn "$TG" --region "$REGION" 2>/dev/null || true
done

echo ""
echo "✅ Force cleanup complete!"
echo "⚠️  Now run: terraform destroy -auto-approve"
