#!/bin/bash
set -euo pipefail

echo "Setting up SSH monitoring with Discord notifications for $(whoami)..."

# Create monitoring directory
sudo mkdir -p /usr/local/bin/monitoring
sudo mkdir -p /etc/monitoring

# Copy scripts
sudo cp check_ssh_auth.sh /usr/local/bin/monitoring/
sudo cp notify_discord.sh /usr/local/bin/monitoring/
sudo chmod +x /usr/local/bin/monitoring/*.sh

# Copy systemd files
sudo cp ssh-monitor.service /etc/systemd/system/
sudo cp ssh-monitor.timer /etc/systemd/system/

# Create Discord configuration
read -p "Enter your Discord webhook URL: " WEBHOOK_URL
read -p "Enter hostname tag (e.g., 'Production-Server'): " HOSTNAME_TAG

sudo tee /etc/monitoring/discord.env > /dev/null <<EOF
DISCORD_WEBHOOK_URL="$WEBHOOK_URL"
HOSTNAME_TAG="$HOSTNAME_TAG"
EOF

sudo chmod 600 /etc/monitoring/discord.env

# Ensure rsyslog is configured for auth logging ($(whoami) default)
sudo systemctl restart rsyslog

# Enable and start the timer
sudo systemctl daemon-reload
sudo systemctl enable ssh-monitor.timer
sudo systemctl start ssh-monitor.timer

echo "✅ SSH monitoring setup complete!"
echo "📊 Check status: sudo systemctl status ssh-monitor.timer"
echo "🔍 View logs: sudo journalctl -u ssh-monitor.service"
echo "🧪 Test notification: sudo /usr/local/bin/monitoring/notify_discord.sh 'Test' 'SSH monitoring is working!'"
echo "📋 Monitor auth log: sudo tail -f /var/log/auth.log"