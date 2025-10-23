#!/bin/bash
# Simple AWS setup - gebruik default profiel zonder SSO complexiteit

echo "=== Simple AWS Configuration Setup ==="
echo ""

# Backup
mv ~/.aws/config ~/.aws/config.backup 2>/dev/null || true

# Create minimal config
cat > ~/.aws/config << 'EOF'
[default]
region = eu-central-1
output = json
EOF

echo "Config created. Now run on YOUR WINDOWS MACHINE:"
echo ""
echo "aws configure export-credentials --profile fictisb_IsbUsersPS-920120424621 --format env"
echo ""
echo "Then copy the AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_SESSION_TOKEN here."
echo ""

read -p "Enter AWS_ACCESS_KEY_ID: " access_key
read -sp "Enter AWS_SECRET_ACCESS_KEY: " secret_key
echo ""
read -sp "Enter AWS_SESSION_TOKEN: " session_token
echo ""

# Set as environment variables for testing
export AWS_ACCESS_KEY_ID="$access_key"
export AWS_SECRET_ACCESS_KEY="$secret_key"
export AWS_SESSION_TOKEN="$session_token"

echo ""
echo "Testing AWS access..."
if aws sts get-caller-identity; then
    echo "✅ AWS credentials work!"
    
    # Create credentials file
    cat > ~/.aws/credentials << EOF
[default]
aws_access_key_id = $access_key
aws_secret_access_key = $secret_key
aws_session_token = $session_token
EOF
    chmod 600 ~/.aws/credentials
    
    # Copy to root
    sudo cp -f ~/.aws/config /root/.aws/config
    sudo cp -f ~/.aws/credentials /root/.aws/credentials
    sudo chmod 600 /root/.aws/credentials
    sudo chown -R root:root /root/.aws
    
    # Update monitoring script
    curl -o /tmp/monitor.sh https://raw.githubusercontent.com/i546927MehdiCetinkaya/casestudy2/main/scripts/ubuntu-monitor-failed-logins.sh
    sudo cp /tmp/monitor.sh /opt/soar-monitor/monitor.sh
    sudo chmod +x /opt/soar-monitor/monitor.sh
    
    # Restart service
    sudo systemctl restart soar-monitor
    
    # Test
    echo ""
    echo "Injecting test event..."
    sudo bash -c 'echo "Failed password for testuser from 1.2.3.4 port 22 ssh2" >> /var/log/auth.log'
    sleep 3
    
    echo ""
    echo "Checking logs..."
    sudo journalctl -u soar-monitor -n 15 --no-pager
else
    echo "❌ Credentials failed"
    exit 1
fi

echo ""
echo "=== Done! ==="
echo ""
echo "NOTE: These are temporary credentials that will expire."
echo "You'll need to refresh them periodically (usually every 12 hours)."
