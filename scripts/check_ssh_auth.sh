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
