#!/bin/bash
# Script to cleanup network dependencies before terraform destroy

set -e

REGION="eu-central-1"
VPC_ID="vpc-091b0c91485383daa"

echo "🔍 Finding and cleaning up network dependencies..."

# Function to delete ENIs in a subnet
cleanup_enis_in_subnet() {
  local SUBNET_ID=$1
  echo "Checking ENIs in subnet: $SUBNET_ID"
  
  ENI_IDS=$(aws ec2 describe-network-interfaces \
    --region "$REGION" \
    --filters "Name=subnet-id,Values=$SUBNET_ID" \
    --query 'NetworkInterfaces[?Status!=`in-use`].NetworkInterfaceId' \
    --output text 2>/dev/null || echo "")
  
  if [ -n "$ENI_IDS" ]; then
    for ENI_ID in $ENI_IDS; do
      echo "Deleting ENI: $ENI_ID"
      aws ec2 delete-network-interface --network-interface-id "$ENI_ID" --region "$REGION" 2>/dev/null || echo "⚠️  Could not delete $ENI_ID"
    done
  fi
}

# Get all subnets in VPC
SUBNET_IDS=$(aws ec2 describe-subnets \
  --region "$REGION" \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[].SubnetId' \
  --output text 2>/dev/null || echo "")

if [ -n "$SUBNET_IDS" ]; then
  for SUBNET_ID in $SUBNET_IDS; do
    cleanup_enis_in_subnet "$SUBNET_ID"
  done
else
  echo "⚠️  No subnets found or VPC doesn't exist"
fi

# Release any Elastic IPs
echo "🔍 Checking for unreleased Elastic IPs..."
EIP_ALLOC_IDS=$(aws ec2 describe-addresses \
  --region "$REGION" \
  --query 'Addresses[?AssociationId==null].AllocationId' \
  --output text 2>/dev/null || echo "")

if [ -n "$EIP_ALLOC_IDS" ]; then
  for ALLOC_ID in $EIP_ALLOC_IDS; do
    echo "Releasing EIP: $ALLOC_ID"
    aws ec2 release-address --allocation-id "$ALLOC_ID" --region "$REGION" 2>/dev/null || echo "⚠️  Could not release $ALLOC_ID"
  done
fi

# Wait for ENI deletion to propagate
echo "⏳ Waiting 30 seconds for ENI deletion to propagate..."
sleep 30

echo "✅ Network cleanup complete!"
