# AWS Credential Refresh Script
Write-Host "AWS Credential Refresh" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host ""

# Check current credentials
Write-Host "Current AWS Configuration:" -ForegroundColor Yellow
aws configure list
Write-Host ""

# Open AWS Access Portal
Write-Host "Opening AWS Access Portal in browser..." -ForegroundColor Green
Start-Process "https://fontys.awsapps.com/start"

Write-Host ""
Write-Host "Steps:" -ForegroundColor Cyan
Write-Host "1. Log in to AWS Access Portal"
Write-Host "2. Select account: 920120424621"
Write-Host "3. Click 'Command line or programmatic access'"
Write-Host "4. Copy credentials from Option 1"
Write-Host "5. Paste them below"
Write-Host ""

Read-Host "Press Enter when ready"

Write-Host ""
Write-Host "Paste the three commands (press Enter twice when done):" -ForegroundColor Green

# Read multiline input
$credentials = @()
do {
    $line = Read-Host
    if ($line) {
        $credentials += $line
    }
} while ($line)

Write-Host ""
Write-Host "Executing credentials..." -ForegroundColor Cyan

# Execute each line
foreach ($cred in $credentials) {
    if ($cred -match '^\$env:AWS_') {
        Invoke-Expression $cred
    }
}

Write-Host ""
Write-Host "Testing credentials..." -ForegroundColor Cyan
$test = aws sts get-caller-identity 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "SUCCESS: Credentials refreshed!" -ForegroundColor Green
    $test | ConvertFrom-Json | Format-List
} else {
    Write-Host "FAILED to set credentials" -ForegroundColor Red
    Write-Host $test
}

Write-Host ""
Write-Host "Note: Credentials will expire. Re-run when needed." -ForegroundColor Yellow
