#!/bin/bash
set -euo pipefail

BACKUP_DIR="/home/$(whoami)/backups"
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

docker exec -t "$CONTAINER_NAME" pg_dump -U "$DB_USER" -d "$DB_NAME" > "$BACKUP_FILE"

# Optional: rotate backups older than 14 days
find "$BACKUP_DIR" -type f -name "${DB_NAME}_*.sql.gz" -mtime +14 -delete
