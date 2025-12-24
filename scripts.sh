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

# Database backup script
sudo nano /usr/local/bin/backup_db.sh


#!/bin/bash
set -euo pipefail

BACKUP_DIR="/home/ubuntu/backups"
CONTAINER_NAME="demo_1_db"
DB_NAME="devops_docker_demo_1"
DB_USER="postgres"
TIMESTAMP="$(date +%Y-%m-%d_%H-%M-%S)"
BACKUP_FILE="${BACKUP_DIR}/${DB_NAME}_${TIMESTAMP}.sql"

mkdir -p "$BACKUP_DIR"
chmod 700 "$BACKUP_DIR"

# Ensure DB container exists/running
docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"

# Optional: wait briefly for DB to be ready (useful after reboot)
for i in {1..30}; do
  if docker exec "$CONTAINER_NAME" pg_isready -U "$DB_USER" >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

# Dump and compress
docker exec -t "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"
gzip -f "$BACKUP_FILE"

# Optional: rotate backups older than 14 days
find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.sql.gz" -mtime +14 -delete

# make script executable
sudo chmod +x /usr/local/bin/backup_db.sh

# Discord webhook configuration

sudo mkdir -p /etc/monitoring
sudo nano /etc/monitoring/discord.env
sudo chmod 600 /etc/monitoring/discord.env

DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1453318183107821702/HSkXiH8FiFhAJmB5x98OZ0-bOvYTcZDntLK-Cv-MbixaI0Z9acn5_1hMyorcSceCdbh8"
HOSTNAME_TAG="$(hostname)"

# Post Discord message script
sudo mkdir -p /usr/local/bin/monitoring
sudo nano /usr/local/bin/monitoring/notify_discord.sh
sudo chmod +x /usr/local/bin/monitoring/notify_discord.sh

#!/bin/bash
set -euo pipefail

# Loads DISCORD_WEBHOOK_URL, HOSTNAME_TAG
source /etc/monitoring/discord.env

if [[ -z "${DISCORD_WEBHOOK_URL:-}" ]]; then
  echo "DISCORD_WEBHOOK_URL not set"
  exit 1
fi

# Usage: notify_discord.sh "TITLE" "MESSAGE"
TITLE="${1:-Alert}"
MESSAGE="${2:-No message}"

# Basic JSON escaping for quotes/newlines
MESSAGE_ESCAPED=$(printf '%s' "$MESSAGE" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n')

payload=$(cat <<EOF
{"content":"**[$HOSTNAME_TAG] $TITLE**\n$MESSAGE_ESCAPED"}
EOF
)

curl -sS -X POST \
  -H "Content-Type: application/json" \
  -d "$payload" \
  "$DISCORD_WEBHOOK_URL" >/dev/null

# Test Discord notification
sudo /usr/local/bin/monitoring/notify_discord.sh "Test" "Discord webhook is working."

# Disk usage monitoring script
sudo nano /usr/local/bin/monitoring/check_disk.sh
sudo chmod +x /usr/local/bin/monitoring/check_disk.sh

#!/bin/bash
set -euo pipefail

THRESHOLD_PERCENT="${THRESHOLD_PERCENT:-85}"
MOUNTPOINT="${MOUNTPOINT:-/}"

USED=$(df -P "$MOUNTPOINT" | awk 'NR==2 {gsub("%","",$5); print $5}')
DETAILS=$(df -hP "$MOUNTPOINT" | awk 'NR==2 {print $0}')

if [[ -z "$USED" ]]; then
  /usr/local/bin/monitoring/notify_discord.sh "Disk check failed" "Could not read df for $MOUNTPOINT"
  exit 2
fi

if (( USED >= THRESHOLD_PERCENT )); then
  /usr/local/bin/monitoring/notify_discord.sh \
    "Disk usage high ($USED% >= $THRESHOLD_PERCENT%)" \
    "Mount: $MOUNTPOINT\n$DETAILS"
fi

# CPU / load monitoring script
sudo nano /usr/local/bin/monitoring/check_cpu_load.sh
sudo chmod +x /usr/local/bin/monitoring/check_cpu_load.sh

#!/bin/bash
set -euo pipefail

# Alert if 1-minute load per CPU core exceeds threshold (e.g., 1.50 means overloaded)
LOAD_PER_CORE_THRESHOLD="${LOAD_PER_CORE_THRESHOLD:-1.50}"

LOAD1=$(awk '{print $1}' /proc/loadavg)
CORES=$(nproc)

# Compute load per core using awk (avoid bc dependency)
LOAD_PER_CORE=$(awk -v l="$LOAD1" -v c="$CORES" 'BEGIN {printf "%.2f", (c>0?l/c:l)}')

# Compare as floats via awk
ALERT=$(awk -v v="$LOAD_PER_CORE" -v t="$LOAD_PER_CORE_THRESHOLD" 'BEGIN {print (v>=t) ? 1 : 0}')

if [[ "$ALERT" -eq 1 ]]; then
  TOP=$(ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6)
  /usr/local/bin/monitoring/notify_discord.sh \
    "High CPU/load (load1=$LOAD1, cores=$CORES, per-core=$LOAD_PER_CORE >= $LOAD_PER_CORE_THRESHOLD)" \
    "Top processes:\n$TOP"
fi

# SSH suspicious behavior monitoring script

sudo nano /usr/local/bin/monitoring/check_ssh_auth.sh
sudo chmod +x /usr/local/bin/monitoring/check_ssh_auth.sh

#!/bin/bash
set -euo pipefail

# Tune these for your lab
WINDOW_MINUTES="${WINDOW_MINUTES:-10}"
FAILED_THRESHOLD="${FAILED_THRESHOLD:-10}"

AUTH_LOG=""
if [[ -f /var/log/auth.log ]]; then
  AUTH_LOG="/var/log/auth.log"        # Ubuntu/Debian
elif [[ -f /var/log/secure ]]; then
  AUTH_LOG="/var/log/secure"          # Amazon Linux/RHEL
else
  /usr/local/bin/monitoring/notify_discord.sh "SSH log check failed" "No auth log found"
  exit 2
fi

# Count failed password attempts within time window using journalctl if available; else fallback to log grep
if command -v journalctl >/dev/null 2>&1; then
  COUNT=$(journalctl -u ssh --since "${WINDOW_MINUTES} min ago" 2>/dev/null | grep -E "Failed password|Invalid user" | wc -l | tr -d ' ')
  SAMPLE=$(journalctl -u ssh --since "${WINDOW_MINUTES} min ago" 2>/dev/null | grep -E "Failed password|Invalid user" | tail -n 10)
else
  # Fallback: crude scan of file; acceptable for lab
  COUNT=$(grep -E "Failed password|Invalid user" "$AUTH_LOG" | tail -n 5000 | wc -l | tr -d ' ')
  SAMPLE=$(grep -E "Failed password|Invalid user" "$AUTH_LOG" | tail -n 10)
fi

if (( COUNT >= FAILED_THRESHOLD )); then
  /usr/local/bin/monitoring/notify_discord.sh \
    "Suspicious SSH activity ($COUNT failures in ~${WINDOW_MINUTES}m)" \
    "Sample events:\n$SAMPLE"
fi


sudo crontab -e

# Disk usage every 5 minutes
*/5 * * * * THRESHOLD_PERCENT=85 MOUNTPOINT=/ /usr/local/bin/monitoring/check_disk.sh

# CPU/load every 2 minutes
*/2 * * * * LOAD_PER_CORE_THRESHOLD=0.20 /usr/local/bin/monitoring/check_cpu_load.sh

# SSH failures every 5 minutes (10-minute window)
*/5 * * * * WINDOW_MINUTES=10 FAILED_THRESHOLD=10 /usr/local/bin/monitoring/check_ssh_auth.sh


# Test CPU load alert

sudo apt update
sudo apt install -y stress
stress --cpu $(nproc) --timeout 120


