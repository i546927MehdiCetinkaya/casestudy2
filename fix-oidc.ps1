# Fix OIDC Trust Relationship for GitHub Actions
# Run this script to configure the IAM role for GitHub OIDC

$RoleName = "githubrepo"
$GitHubOrg = "i546927MehdiCetinkaya"
$GitHubRepo = "casestudy2"
$AccountId = "920120424621"

Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  GitHub OIDC Configuration for AWS IAM Role" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Check if OIDC provider exists
Write-Host "[1/4] Checking OIDC Provider..." -ForegroundColor Yellow

$oidcExists = aws iam list-open-id-connect-providers --output json | ConvertFrom-Json | 
    Select-Object -ExpandProperty OpenIDConnectProviderList | 
    Where-Object { $_.Arn -like "*token.actions.githubusercontent.com*" }

if ($oidcExists) {
    Write-Host "✓ OIDC Provider already exists" -ForegroundColor Green
} else {
    Write-Host "✗ Creating OIDC Provider..." -ForegroundColor Red
    
    # Get GitHub's thumbprint
    $thumbprint = "6938fd4d98bab03faadb97b34396831e3780aea1"
    
    aws iam create-open-id-connect-provider `
        --url "https://token.actions.githubusercontent.com" `
        --client-id-list "sts.amazonaws.com" `
        --thumbprint-list $thumbprint
    
    Write-Host "✓ OIDC Provider created" -ForegroundColor Green
}

# Step 2: Create trust policy
Write-Host ""
Write-Host "[2/4] Creating Trust Policy..." -ForegroundColor Yellow

$trustPolicy = @{
    Version = "2012-10-17"
    Statement = @(
        @{
            Effect = "Allow"
            Principal = @{
                Federated = "arn:aws:iam::${AccountId}:oidc-provider/token.actions.githubusercontent.com"
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = @{
                StringEquals = @{
                    "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
                }
                StringLike = @{
                    "token.actions.githubusercontent.com:sub" = "repo:${GitHubOrg}/${GitHubRepo}:*"
                }
            }
        }
    )
} | ConvertTo-Json -Depth 10

# Save to file
$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8
Write-Host "✓ Trust policy created" -ForegroundColor Green

# Step 3: Check if role exists, if not create it
Write-Host ""
Write-Host "[3/4] Checking IAM Role..." -ForegroundColor Yellow

try {
    $roleExists = aws iam get-role --role-name $RoleName 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Role exists, updating trust policy..." -ForegroundColor Green
        
        aws iam update-assume-role-policy `
            --role-name $RoleName `
            --policy-document file://trust-policy.json
        
        Write-Host "✓ Trust policy updated" -ForegroundColor Green
    }
} catch {
    Write-Host "✗ Role doesn't exist, creating..." -ForegroundColor Red
    
    aws iam create-role `
        --role-name $RoleName `
        --assume-role-policy-document file://trust-policy.json `
        --description "GitHub Actions OIDC Role for Case Study 2"
    
    Write-Host "✓ Role created" -ForegroundColor Green
}

# Step 4: Attach policies to role
Write-Host ""
Write-Host "[4/4] Attaching Policies..." -ForegroundColor Yellow

# For simplicity, attaching AdministratorAccess (adjust in production!)
aws iam attach-role-policy `
    --role-name $RoleName `
    --policy-arn "arn:aws:iam::aws:policy/AdministratorAccess"

Write-Host "✓ Policies attached" -ForegroundColor Green

# Display summary
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "  Configuration Complete!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Role ARN: arn:aws:iam::${AccountId}:role/${RoleName}" -ForegroundColor White
Write-Host "Repository: ${GitHubOrg}/${GitHubRepo}" -ForegroundColor White
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Commit and push to trigger GitHub Actions" -ForegroundColor White
Write-Host "2. GitHub Actions should now be able to assume the role" -ForegroundColor White
Write-Host ""

# Cleanup
Remove-Item "trust-policy.json" -Force
