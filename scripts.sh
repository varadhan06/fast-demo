#!/bin/bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
sudo apt install docker-compose-plugin -y
sudo apt install git -y

# Clone the repository
cd /home/ubuntu/
git clone https://github.com/varadhan06/fast-demo.git
cd fast-demo

# Start the containers
docker compose up -d

# Wait for containers to be ready
sleep 30

# Initialize the database
docker compose exec backend python setup.py

# Database backup script
sudo cp /home/ubuntu/fast-demo/scripts/backup_db.sh /usr/local/bin/backup_db.sh


# make script executable
sudo chmod +x /usr/local/bin/backup_db.sh

# Discord webhook configuration

sudo mkdir -p /etc/monitoring
sudo nano /etc/monitoring/discord.env


# Paste the following content into discord.env

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/your_webhook_url_here"
HOSTNAME_TAG="$(hostname)"

# Until here, then save and exit the editor

# set permissions
sudo chmod 600 /etc/monitoring/discord.env


# Post Discord message script
sudo mkdir -p /usr/local/bin/monitoring
cp /home/ubuntu/fast-demo/scripts/notify_discord.sh /usr/local/bin/monitoring/notify_discord.sh

# make script executable
sudo chmod +x /usr/local/bin/monitoring/notify_discord.sh

# Test Discord notification
sudo /usr/local/bin/monitoring/notify_discord.sh "Test" "Discord webhook is working."

# Disk usage monitoring script
sudo cp /home/ubuntu/fast-demo/scripts/check_disk.sh /usr/local/bin/monitoring/check_disk.sh

# make script executable
sudo chmod +x /usr/local/bin/monitoring/check_disk.sh

# CPU / load monitoring script
sudo cp /home/ubuntu/fast-demo/scripts/check_cpu_load.sh /usr/local/bin/monitoring/check_cpu_load.sh

# make script executable
sudo chmod +x /usr/local/bin/monitoring/check_cpu_load.sh

# SSH suspicious behavior monitoring script
sudo cp /home/ubuntu/fast-demo/scripts/check_ssh_auth.sh /usr/local/bin/monitoring/check_ssh_auth.sh

# make script executable
sudo chmod +x /usr/local/bin/monitoring/check_ssh_auth.sh

# Set up automated cron jobs
chmod +x /home/ubuntu/fast-demo/scripts/setup_cron_jobs.sh && /home/ubuntu/fast-demo/scripts/setup_cron_jobs.sh


# Test CPU load alert
sudo apt update
sudo apt install -y stress
stress --cpu $(nproc) --timeout 120


