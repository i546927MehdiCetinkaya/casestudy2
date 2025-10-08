# Force cleanup script for AWS resources (Powershell version)
# Run this script in Powershell to manually clean up all resources

$Region = "eu-central-1"
$VpcId = "vpc-091b0c91485383daa"
$Project = "casestudy2"
$Env = "dev"

Write-Host "🔥 FORCE CLEANUP - Removing all resources manually"
Write-Host "=================================================="

# 1. Delete EKS cluster (if exists)
$EksCluster = "$Project-$Env-eks"
$Cluster = aws eks describe-cluster --name $EksCluster --region $Region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Deleting EKS node group..."
    $NodeGroup = aws eks list-nodegroups --cluster-name $EksCluster --region $Region --query 'nodegroups[0]' --output text 2>$null
    if ($NodeGroup -and $NodeGroup -ne "None") {
        aws eks delete-nodegroup --cluster-name $EksCluster --nodegroup-name $NodeGroup --region $Region 2>$null
        Write-Host "Waiting for node group deletion (5-10 min)..."
        aws eks wait nodegroup-deleted --cluster-name $EksCluster --nodegroup-name $NodeGroup --region $Region 2>$null
    }
    Write-Host "Deleting EKS cluster..."
    aws eks delete-cluster --name $EksCluster --region $Region 2>$null
    Write-Host "Waiting for cluster deletion (5-10 min)..."
    aws eks wait cluster-deleted --name $EksCluster --region $Region 2>$null
}

# 2. Delete Lambda functions
Write-Host "Deleting Lambda functions..."
$Lambdas = aws lambda list-functions --region $Region --query "Functions[?starts_with(FunctionName, '$Project-$Env')].FunctionName" --output text 2>$null
foreach ($Func in $Lambdas) {
    Write-Host "  Deleting: $Func"
    aws lambda delete-function --function-name $Func --region $Region 2>$null
}

# 3. Wait for Lambda ENIs to be released
Write-Host "Waiting 90 seconds for Lambda ENIs to be released..."
Start-Sleep -Seconds 90

# 4. Delete NAT Gateways
Write-Host "Deleting NAT Gateways..."
$NatGws = aws ec2 describe-nat-gateways --region $Region --filter "Name=vpc-id,Values=$VpcId" "Name=state,Values=available" --query 'NatGateways[].NatGatewayId' --output text 2>$null
foreach ($NatGw in $NatGws) {
    Write-Host "  Deleting NAT Gateway: $NatGw"
    aws ec2 delete-nat-gateway --nat-gateway-id $NatGw --region $Region 2>$null
}
if ($NatGws) {
    Write-Host "  Waiting 3 minutes for NAT Gateways to be deleted..."
    Start-Sleep -Seconds 180
}

# 5. Unmap and release all Elastic IPs associated with the VPC
Write-Host "Unmapping and releasing Elastic IPs..."
$Eips = aws ec2 describe-addresses --region $Region --query "Addresses[?VpcId=='$VpcId']" --output json 2>$null | ConvertFrom-Json
foreach ($Eip in $Eips) {
    if ($Eip.AssociationId) {
        Write-Host "  Unmapping EIP association: $($Eip.AssociationId)"
        aws ec2 disassociate-address --association-id $Eip.AssociationId --region $Region 2>$null
    }
    if ($Eip.AllocationId) {
        Write-Host "  Releasing EIP: $($Eip.AllocationId)"
        aws ec2 release-address --allocation-id $Eip.AllocationId --region $Region 2>$null
    }
}

# 5b. Detach and delete Internet Gateway
Write-Host "Detaching and deleting Internet Gateway..."
$IgwId = aws ec2 describe-internet-gateways --region $Region --filters "Name=attachment.vpc-id,Values=$VpcId" --query 'InternetGateways[0].InternetGatewayId' --output text 2>$null
if ($IgwId -and $IgwId -ne "None") {
    Write-Host "  Detaching IGW $IgwId from VPC $VpcId"
    aws ec2 detach-internet-gateway --internet-gateway-id $IgwId --vpc-id $VpcId --region $Region 2>$null
    Start-Sleep -Seconds 5
    Write-Host "  Deleting IGW $IgwId"
    aws ec2 delete-internet-gateway --internet-gateway-id $IgwId --region $Region 2>$null
}

# 6. Delete all ENIs in VPC
Write-Host "Force deleting ENIs..."
$Subnets = aws ec2 describe-subnets --region $Region --filters "Name=vpc-id,Values=$VpcId" --query 'Subnets[].SubnetId' --output text 2>$null
foreach ($Subnet in $Subnets) {
    Write-Host "  Checking subnet: $Subnet"
    $Enis = aws ec2 describe-network-interfaces --region $Region --filters "Name=subnet-id,Values=$Subnet" --query 'NetworkInterfaces[].NetworkInterfaceId' --output text 2>$null
    foreach ($Eni in $Enis) {
        Write-Host "    Detaching ENI: $Eni"
        $AttachmentId = aws ec2 describe-network-interfaces --region $Region --network-interface-ids $Eni --query 'NetworkInterfaces[0].Attachment.AttachmentId' --output text 2>$null
        if ($AttachmentId -and $AttachmentId -ne "None") {
            aws ec2 detach-network-interface --attachment-id $AttachmentId --region $Region --force 2>$null
            Start-Sleep -Seconds 5
        }
        Write-Host "    Deleting ENI: $Eni"
        aws ec2 delete-network-interface --network-interface-id $Eni --region $Region 2>$null
    }
}

# 7. Delete Load Balancers
Write-Host "Deleting Load Balancers..."
$Albs = aws elbv2 describe-load-balancers --region $Region --query "LoadBalancers[?VpcId=='$VpcId'].LoadBalancerArn" --output text 2>$null
foreach ($Alb in $Albs) {
    Write-Host "  Deleting ALB: $Alb"
    aws elbv2 delete-load-balancer --load-balancer-arn $Alb --region $Region 2>$null
}
if ($Albs) {
    Write-Host "  Waiting 60 seconds for ALBs to be deleted..."
    Start-Sleep -Seconds 60
}

# 8. Delete Target Groups
Write-Host "Deleting Target Groups..."
$Tgs = aws elbv2 describe-target-groups --region $Region --query "TargetGroups[?VpcId=='$VpcId'].TargetGroupArn" --output text 2>$null
foreach ($Tg in $Tgs) {
    Write-Host "  Deleting TG: $Tg"
    aws elbv2 delete-target-group --target-group-arn $Tg --region $Region 2>$null
}

Write-Host ""
Write-Host "✅ Force cleanup complete!"
Write-Host "⚠️  Now run: terraform destroy -auto-approve"
