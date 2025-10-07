# Import existing AWS resources into Terraform state
# This fixes the "already exists" errors

Write-Host "=== Importing Existing AWS Resources ===" -ForegroundColor Cyan

$region = "eu-central-1"
$project = "casestudy2-dev"

# Change to terraform directory
Set-Location terraform

# Initialize Terraform
Write-Host "`nInitializing Terraform..." -ForegroundColor Yellow
terraform init

# Import ALB
Write-Host "`nImporting ALB..." -ForegroundColor Yellow
$albArn = aws elbv2 describe-load-balancers --region $region --names "$project-alb" --query "LoadBalancers[0].LoadBalancerArn" --output text 2>$null
if ($albArn -and $albArn -ne "None") {
    Write-Host "  Found ALB: $albArn" -ForegroundColor Green
    terraform import aws_lb.main $albArn
} else {
    Write-Host "  No ALB found to import" -ForegroundColor Gray
}

# Import EKS Cluster
Write-Host "`nImporting EKS Cluster..." -ForegroundColor Yellow
$eksExists = aws eks describe-cluster --name "$project-eks" --region $region 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Found EKS cluster: $project-eks" -ForegroundColor Green
    terraform import aws_eks_cluster.main "$project-eks"
} else {
    Write-Host "  No EKS cluster found to import" -ForegroundColor Gray
}

# Import Lambda Event Source Mappings
Write-Host "`nImporting Lambda Event Source Mappings..." -ForegroundColor Yellow

# Parser SQS mapping
$parserUuid = aws lambda list-event-source-mappings --function-name "$project-parser" --region $region --query "EventSourceMappings[0].UUID" --output text 2>$null
if ($parserUuid -and $parserUuid -ne "None") {
    Write-Host "  Found parser SQS mapping: $parserUuid" -ForegroundColor Green
    terraform import aws_lambda_event_source_mapping.parser_sqs $parserUuid
}

# Engine SQS mapping
$engineUuid = aws lambda list-event-source-mappings --function-name "$project-engine" --region $region --query "EventSourceMappings[0].UUID" --output text 2>$null
if ($engineUuid -and $engineUuid -ne "None") {
    Write-Host "  Found engine SQS mapping: $engineUuid" -ForegroundColor Green
    terraform import aws_lambda_event_source_mapping.engine_sqs $engineUuid
}

# Notify SQS mapping
$notifyUuid = aws lambda list-event-source-mappings --function-name "$project-notify" --region $region --query "EventSourceMappings[0].UUID" --output text 2>$null
if ($notifyUuid -and $notifyUuid -ne "None") {
    Write-Host "  Found notify SQS mapping: $notifyUuid" -ForegroundColor Green
    terraform import aws_lambda_event_source_mapping.notify_sqs $notifyUuid
}

# Remediate SQS mapping
$remediateUuid = aws lambda list-event-source-mappings --function-name "$project-remediate" --region $region --query "EventSourceMappings[0].UUID" --output text 2>$null
if ($remediateUuid -and $remediateUuid -ne "None") {
    Write-Host "  Found remediate SQS mapping: $remediateUuid" -ForegroundColor Green
    terraform import aws_lambda_event_source_mapping.remediate_sqs $remediateUuid
}

Write-Host "`n=== Import Complete ===" -ForegroundColor Green
Write-Host "Run 'terraform plan' to verify the state" -ForegroundColor Yellow

Set-Location ..
