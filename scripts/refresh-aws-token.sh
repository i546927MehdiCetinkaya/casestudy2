#!/bin/bash
# AWS SSO Token Refresh Script voor Ubuntu Server
# Run dit script als je token is expired

echo "🔄 Refreshing AWS SSO Credentials..."
echo ""

# Check if AWS CLI v2 is installed
if ! aws --version | grep -q "aws-cli/2"; then
    echo "⚠️  AWS CLI v2 is required for SSO"
    echo "Installing AWS CLI v2..."
    
    cd /tmp
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install --update
    
    echo "✅ AWS CLI v2 installed"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Hoe te vernieuwen:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "OPTIE A: Op Windows machine (waar je SSO hebt):"
echo "  1. Run in PowerShell: aws sso login --profile fictisb"
echo "  2. Kopieer nieuwe credentials naar Ubuntu"
echo ""
echo "OPTIE B: Gebruik IAM User credentials (makkelijker):"
echo "  1. Maak IAM User in AWS Console"
echo "  2. Geef permissions: events:PutEvents"
echo "  3. Genereer Access Keys"
echo "  4. Run: aws configure (zonder session token!)"
echo ""
echo "OPTIE C: EC2 Instance Role (beste practice):"
echo "  Als dit een EC2 instance is, gebruik IAM Role"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
