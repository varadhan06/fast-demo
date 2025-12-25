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
