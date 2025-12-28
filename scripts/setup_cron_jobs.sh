#!/bin/bash
set -euo pipefail

echo "Setting up cron jobs for monitoring..."

# Create cron jobs for root (monitoring requires root access)
sudo tee /etc/cron.d/monitoring << 'EOF'
# Disk usage every 2 minutes
*/2 * * * * root THRESHOLD_PERCENT=85 MOUNTPOINT=/ /usr/local/bin/monitoring/check_disk.sh

# CPU/load every 2 minutes  
*/2 * * * * root LOAD_PER_CORE_THRESHOLD=0.20 /usr/local/bin/monitoring/check_cpu_load.sh

# SSH monitoring every 2 minutes
*/2 * * * * root WINDOW_MINUTES=5 FAILED_THRESHOLD=3 /usr/local/bin/monitoring/check_ssh_auth.sh

# Database backup daily at 2 AM
0 2 * * * root /usr/local/bin/backup_db.sh
EOF

# Set proper permissions
sudo chmod 644 /etc/cron.d/monitoring

# Restart cron service
sudo systemctl restart cron

echo "✅ Cron jobs installed successfully!"
echo "📋 View jobs: sudo cat /etc/cron.d/monitoring"
echo "📊 Check cron logs: sudo journalctl -u cron"