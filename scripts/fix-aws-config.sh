#!/bin/bash
# Fix AWS Config on Ubuntu

echo "=== Fixing AWS Configuration ==="
echo ""

# Backup old config
echo "1. Backing up old config..."
mv ~/.aws/config ~/.aws/config.backup 2>/dev/null || true

# Create clean config
echo "2. Creating new AWS config..."
cat > ~/.aws/config << 'EOF'
[default]
region = eu-central-1
output = json

[profile fictisb_IsbUsersPS-920120424621]
sso_session = dsa
sso_account_id = 920120424621
sso_role_name = fictisb_IsbUsersPS
region = eu-central-1
output = json

[sso-session dsa]
sso_start_url = https://fontys.awsapps.com/start/#
sso_region = eu-central-1
sso_registration_scopes = sso:account:access
EOF

echo "3. Config file created:"
cat ~/.aws/config
echo ""

echo "4. Now login with SSO..."
aws sso login --profile fictisb_IsbUsersPS-920120424621

echo ""
echo "5. Testing AWS access..."
aws sts get-caller-identity --profile fictisb_IsbUsersPS-920120424621

echo ""
echo "6. Copying to root..."
sudo cp -f ~/.aws/config /root/.aws/config
sudo mkdir -p /root/.aws/sso/cache
sudo cp -r ~/.aws/sso/cache/* /root/.aws/sso/cache/ 2>/dev/null || true
sudo chown -R root:root /root/.aws

echo ""
echo "7. Restarting soar-monitor service..."
sudo systemctl restart soar-monitor

echo ""
echo "8. Injecting test event..."
sudo bash -c 'echo "Failed password for testuser from 10.20.30.40 port 22 ssh2" >> /var/log/auth.log'

echo ""
echo "9. Waiting 3 seconds..."
sleep 3

echo ""
echo "10. Checking service logs..."
sudo journalctl -u soar-monitor -n 15 --no-pager

echo ""
echo "=== Done! ==="
