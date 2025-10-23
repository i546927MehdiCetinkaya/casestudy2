#!/bin/bash
# Fix AWS Config met Access Keys (geen SSO)

echo "=== AWS Configuration Setup (Access Keys) ==="
echo ""
echo "Je moet AWS Access Keys gebruiken voor de monitoring service."
echo "Ga naar AWS Console > IAM > Security credentials > Create access key"
echo ""

# Backup old config
echo "1. Backing up old config..."
mv ~/.aws/config ~/.aws/config.backup 2>/dev/null || true
mv ~/.aws/credentials ~/.aws/credentials.backup 2>/dev/null || true

# Create simple config without SSO
echo "2. Creating new AWS config..."
cat > ~/.aws/config << 'EOF'
[default]
region = eu-central-1
output = json
EOF

echo ""
read -p "Enter AWS Access Key ID: " aws_access_key
read -sp "Enter AWS Secret Access Key: " aws_secret_key
echo ""

# Create credentials file
cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $aws_access_key
aws_secret_access_key = $aws_secret_key
EOF

chmod 600 ~/.aws/credentials

echo ""
echo "3. Testing AWS access..."
if aws sts get-caller-identity; then
    echo "✅ AWS credentials work!"
else
    echo "❌ AWS credentials failed. Please check your keys."
    exit 1
fi

echo ""
echo "4. Copying to root..."
sudo cp -f ~/.aws/config /root/.aws/config
sudo cp -f ~/.aws/credentials /root/.aws/credentials
sudo chmod 600 /root/.aws/credentials
sudo chown -R root:root /root/.aws

# Update monitoring script to NOT use profile
echo ""
echo "5. Updating monitoring script to use default credentials..."
sudo sed -i 's/AWS_PROFILE=.*/# AWS_PROFILE removed - using default credentials/' /opt/soar-monitor/monitor.sh
sudo sed -i 's/--profile "\$AWS_PROFILE"//' /opt/soar-monitor/monitor.sh

echo ""
echo "6. Restarting soar-monitor service..."
sudo systemctl restart soar-monitor

echo ""
echo "7. Injecting test event..."
sudo bash -c 'echo "Failed password for testuser from 10.20.30.40 port 22 ssh2" >> /var/log/auth.log'

echo ""
echo "8. Waiting 3 seconds..."
sleep 3

echo ""
echo "9. Checking service logs..."
sudo journalctl -u soar-monitor -n 15 --no-pager

echo ""
echo "=== Done! ==="
