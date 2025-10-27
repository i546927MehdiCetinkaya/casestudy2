# Package Lambda Functions
Write-Host "Packaging Lambda functions..." -ForegroundColor Cyan

$lambdas = @("ingress", "parser", "engine", "notify", "remediate")

foreach ($lambda in $lambdas) {
    Write-Host "  Zipping $lambda..." -ForegroundColor Yellow
    
    $lambdaDir = "../lambda/$lambda"
    $zipFile = "$lambdaDir/$lambda.zip"
    
    # Remove old zip if exists
    if (Test-Path $zipFile) {
        Remove-Item $zipFile
    }
    
    # Create zip with Python file and requirements.txt
    Compress-Archive -Path "$lambdaDir/$lambda.py", "$lambdaDir/requirements.txt" -DestinationPath $zipFile -Force
    
    Write-Host "  Created $zipFile" -ForegroundColor Green
}

Write-Host ""
Write-Host "All Lambda functions packaged successfully!" -ForegroundColor Green
