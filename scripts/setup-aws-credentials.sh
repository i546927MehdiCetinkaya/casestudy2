#!/bin/bash
# setup-aws-credentials.sh
# Setup AWS credentials op Ubuntu server voor EventBridge access

echo "🔧 AWS Credentials Setup voor SOAR Monitoring"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI niet gevonden!"
    echo "Installeer eerst: sudo apt install awscli"
    exit 1
fi

echo "✅ AWS CLI gevonden"
echo ""

# Option 1: Gebruik bestaande GitHub OIDC credentials
echo "Optie 1: Gebruik GitHub OIDC Role credentials"
echo "-----------------------------------------------"
echo "Deze credentials staan in je GitHub Secrets."
echo ""
read -p "Heb je Access Key ID van GitHub? (y/n): " has_keys

if [ "$has_keys" = "y" ]; then
    read -p "AWS Access Key ID: " access_key
    read -sp "AWS Secret Access Key: " secret_key
    echo ""
    read -p "Role ARN (arn:aws:iam::920120424621:role/...): " role_arn
    
    # Configureer AWS CLI
    aws configure set aws_access_key_id "$access_key"
    aws configure set aws_secret_access_key "$secret_key"
    aws configure set region eu-central-1
    aws configure set output json
    
    echo ""
    echo "✅ AWS credentials geconfigureerd!"
    echo ""
    
    # Test credentials
    echo "🧪 Test AWS credentials..."
    if aws sts get-caller-identity; then
        echo ""
        echo "✅ AWS credentials werken!"
        echo ""
        
        # Test assume role
        echo "🧪 Test AssumeRole naar EventBridge role..."
        if aws sts assume-role --role-arn "$role_arn" --role-session-name "test-session" --region eu-central-1; then
            echo ""
            echo "✅ AssumeRole werkt!"
            echo ""
            echo "Nu het monitoring script updaten met Role ARN..."
            read -p "Pad naar ubuntu-monitor-failed-logins.sh: " script_path
            sed -i "s|REPLACE_WITH_ROLE_ARN|$role_arn|g" "$script_path"
            echo "✅ Script updated met Role ARN!"
        else
            echo ""
            echo "❌ AssumeRole test failed!"
            echo "Check of je IP (192.168.154.13) toegang heeft tot het role"
        fi
    else
        echo ""
        echo "❌ AWS credentials test failed!"
        echo "Check je Access Key ID en Secret Access Key"
    fi
else
    echo ""
    echo "Optie 2: Maak IAM Role met AssumeRole"
    echo "---------------------------------------"
    echo ""
    echo "Volg deze stappen:"
    echo "1. Ga naar AWS Console: https://console.aws.amazon.com/iam/home#/roles"
    echo "2. Create role → Custom trust policy"
    echo "3. Gebruik deze trust policy:"
    echo ""
    cat <<'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::920120424621:root"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "IpAddress": {
          "aws:SourceIp": "192.168.154.13/32"
        }
      }
    }
  ]
}
EOF
    echo ""
    echo "4. Attach policy: AmazonEventBridgeFullAccess"
    echo "5. Role name: ubuntu-eventbridge-sender"
    echo ""
    echo "Daarna: run dit script opnieuw met access keys"
fi

echo ""
echo "📖 Zie UBUNTU-INTEGRATION-GUIDE.md voor meer info"
