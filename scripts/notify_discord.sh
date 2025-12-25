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