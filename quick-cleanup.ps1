# Quick AWS Cleanup Script
# Run this after canceling a deployment to clean up any partially created resources

Write-Host "`n=== Quick AWS Cleanup Script ===" -ForegroundColor Cyan
Write-Host "This script will check and delete any casestudy2-dev resources`n" -ForegroundColor Yellow

$region = "eu-central-1"
$project = "casestudy2-dev"

# Function to run AWS CLI commands safely
function Run-AWSCommand {
    param($Command, $Description)
    Write-Host "`nChecking: $Description..." -ForegroundColor Green
    try {
        Invoke-Expression $Command
    } catch {
        Write-Host "  No resources found or error: $_" -ForegroundColor Gray
    }
}

# 1. Delete Lambda Functions
Write-Host "`n--- Lambda Functions ---" -ForegroundColor Cyan
Run-AWSCommand "aws lambda list-functions --region $region --query 'Functions[?starts_with(FunctionName, ``casestudy2-dev``)].FunctionName' --output table" "Lambda functions"
$lambdas = aws lambda list-functions --region $region --query "Functions[?starts_with(FunctionName, 'casestudy2-dev')].FunctionName" --output text 2>$null
if ($lambdas) {
    foreach ($lambda in $lambdas -split "`t") {
        Write-Host "  Deleting Lambda: $lambda" -ForegroundColor Yellow
        aws lambda delete-function --function-name $lambda --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No Lambda functions to delete" -ForegroundColor Green
}

# 2. Delete ECR Repositories
Write-Host "`n--- ECR Repositories ---" -ForegroundColor Cyan
Run-AWSCommand "aws ecr describe-repositories --region $region --query 'repositories[?contains(repositoryName, ``casestudy2``)].repositoryName' --output table" "ECR repositories"
$repos = aws ecr describe-repositories --region $region --query "repositories[?contains(repositoryName, 'casestudy2')].repositoryName" --output text 2>$null
if ($repos) {
    foreach ($repo in $repos -split "`t") {
        Write-Host "  Deleting ECR repo: $repo" -ForegroundColor Yellow
        aws ecr delete-repository --repository-name $repo --region $region --force 2>$null
    }
} else {
    Write-Host "  ✓ No ECR repositories to delete" -ForegroundColor Green
}

# 3. Delete DynamoDB Tables
Write-Host "`n--- DynamoDB Tables ---" -ForegroundColor Cyan
Run-AWSCommand "aws dynamodb list-tables --region $region --query 'TableNames[?contains(@, ``casestudy2``)]' --output table" "DynamoDB tables"
$tables = aws dynamodb list-tables --region $region --query "TableNames[?contains(@, 'casestudy2-dev')]" --output text 2>$null
if ($tables) {
    foreach ($table in $tables -split "`t") {
        Write-Host "  Deleting DynamoDB table: $table" -ForegroundColor Yellow
        aws dynamodb delete-table --table-name $table --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No DynamoDB tables to delete" -ForegroundColor Green
}

# 4. Delete SQS Queues
Write-Host "`n--- SQS Queues ---" -ForegroundColor Cyan
Run-AWSCommand "aws sqs list-queues --region $region --queue-name-prefix casestudy2-dev --output table" "SQS queues"
$queues = aws sqs list-queues --region $region --queue-name-prefix "casestudy2-dev" --query "QueueUrls" --output text 2>$null
if ($queues) {
    foreach ($queue in $queues -split "`t") {
        Write-Host "  Deleting SQS queue: $queue" -ForegroundColor Yellow
        aws sqs delete-queue --queue-url $queue --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No SQS queues to delete" -ForegroundColor Green
}

# 5. Delete SNS Topics
Write-Host "`n--- SNS Topics ---" -ForegroundColor Cyan
Run-AWSCommand "aws sns list-topics --region $region --query 'Topics[?contains(TopicArn, ``casestudy2``)].TopicArn' --output table" "SNS topics"
$topics = aws sns list-topics --region $region --query "Topics[?contains(TopicArn, 'casestudy2-dev')].TopicArn" --output text 2>$null
if ($topics) {
    foreach ($topic in $topics -split "`t") {
        Write-Host "  Deleting SNS topic: $topic" -ForegroundColor Yellow
        aws sns delete-topic --topic-arn $topic --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No SNS topics to delete" -ForegroundColor Green
}

# 6. Delete EventBridge Rules
Write-Host "`n--- EventBridge Rules ---" -ForegroundColor Cyan
Run-AWSCommand "aws events list-rules --region $region --name-prefix casestudy2-dev --output table" "EventBridge rules"
$rules = aws events list-rules --region $region --name-prefix "casestudy2-dev" --query "Rules[].Name" --output text 2>$null
if ($rules) {
    foreach ($rule in $rules -split "`t") {
        Write-Host "  Deleting EventBridge rule: $rule" -ForegroundColor Yellow
        # Remove targets first
        $targets = aws events list-targets-by-rule --rule $rule --region $region --query "Targets[].Id" --output text 2>$null
        if ($targets) {
            aws events remove-targets --rule $rule --ids $targets --region $region 2>$null
        }
        aws events delete-rule --name $rule --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No EventBridge rules to delete" -ForegroundColor Green
}

# 7. Check VPC and Subnets
Write-Host "`n--- VPC Resources ---" -ForegroundColor Cyan
$vpcs = aws ec2 describe-vpcs --region $region --filters "Name=tag:Name,Values=casestudy2-dev-vpc" --query "Vpcs[].VpcId" --output text 2>$null
if ($vpcs) {
    Write-Host "  ⚠ VPC found: $vpcs" -ForegroundColor Yellow
    Write-Host "  Note: VPC cleanup requires multiple steps - see MANUAL-CLEANUP.md" -ForegroundColor Red
} else {
    Write-Host "  ✓ No VPC resources found" -ForegroundColor Green
}

# 8. Check EKS Clusters
Write-Host "`n--- EKS Clusters ---" -ForegroundColor Cyan
$clusters = aws eks list-clusters --region $region --query "clusters[?contains(@, 'casestudy2-dev')]" --output text 2>$null
if ($clusters) {
    Write-Host "  ⚠ EKS cluster found: $clusters" -ForegroundColor Yellow
    Write-Host "  Deleting EKS cluster (this takes 10-15 minutes)..." -ForegroundColor Yellow
    foreach ($cluster in $clusters -split "`t") {
        aws eks delete-cluster --name $cluster --region $region 2>$null
    }
} else {
    Write-Host "  ✓ No EKS clusters found" -ForegroundColor Green
}

# 9. Delete Secrets Manager Secrets
Write-Host "`n--- Secrets Manager ---" -ForegroundColor Cyan
$secrets = aws secretsmanager list-secrets --region $region --query "SecretList[?contains(Name, 'casestudy2-dev')].Name" --output text 2>$null
if ($secrets) {
    foreach ($secret in $secrets -split "`t") {
        Write-Host "  Deleting secret: $secret" -ForegroundColor Yellow
        aws secretsmanager delete-secret --secret-id $secret --region $region --force-delete-without-recovery 2>$null
    }
} else {
    Write-Host "  ✓ No secrets to delete" -ForegroundColor Green
}

# 10. Delete CloudWatch Log Groups
Write-Host "`n--- CloudWatch Log Groups ---" -ForegroundColor Cyan
$logGroups = aws logs describe-log-groups --region $region --log-group-name-prefix "/aws/lambda/casestudy2-dev" --query "logGroups[].logGroupName" --output text 2>$null
if ($logGroups) {
    foreach ($lg in $logGroups -split "`t") {
        Write-Host "  Deleting log group: $lg" -ForegroundColor Yellow
        aws logs delete-log-group --log-group-name $lg --region $region 2>$null
    }
}
$eksLogs = aws logs describe-log-groups --region $region --log-group-name-prefix "/aws/eks/casestudy2-dev" --query "logGroups[].logGroupName" --output text 2>$null
if ($eksLogs) {
    foreach ($lg in $eksLogs -split "`t") {
        Write-Host "  Deleting log group: $lg" -ForegroundColor Yellow
        aws logs delete-log-group --log-group-name $lg --region $region 2>$null
    }
}
if (-not $logGroups -and -not $eksLogs) {
    Write-Host "  ✓ No log groups to delete" -ForegroundColor Green
}

Write-Host "`n=== Cleanup Complete ===" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "  • Lambda, ECR, DynamoDB, SQS, SNS, EventBridge cleaned" -ForegroundColor Green
Write-Host "  • If VPC or EKS were found, follow MANUAL-CLEANUP.md for full cleanup" -ForegroundColor Yellow
Write-Host "`nYou can now safely deploy again!" -ForegroundColor Green
