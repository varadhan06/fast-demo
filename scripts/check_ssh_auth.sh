#!/bin/bash
set -euo pipefail

# Configuration
WINDOW_MINUTES="${WINDOW_MINUTES:-10}"
FAILED_THRESHOLD="${FAILED_THRESHOLD:-5}"
NOTIFY_SCRIPT="/usr/local/bin/monitoring/notify_discord.sh"

# Find auth log
if [[ -f /var/log/auth.log ]]; then
  AUTH_LOG="/var/log/auth.log"
else
  "$NOTIFY_SCRIPT" "SSH Monitor Error" "No auth log found"
  exit 2
fi

# Get recent log entries from auth.log directly
RECENT_LOGS=$(tail -n 1000 "$AUTH_LOG" 2>/dev/null || echo "")

# Check for failed password attempts
PASSWORD_FAILURES=$(echo "$RECENT_LOGS" | grep -E "Failed password|Invalid user" | wc -l | tr -d ' ')
if (( PASSWORD_FAILURES >= FAILED_THRESHOLD )); then
  SAMPLE=$(echo "$RECENT_LOGS" | grep -E "Failed password|Invalid user" | tail -n 5)
  "$NOTIFY_SCRIPT" "🚨 SSH Password Attacks ($PASSWORD_FAILURES attempts)" "$SAMPLE"
fi

# Check for SSH key authentication failures
KEY_FAILURES=$(echo "$RECENT_LOGS" | grep -E "Connection closed by authenticating user|Failed publickey|Invalid user.*ssh2" | wc -l | tr -d ' ')
if (( KEY_FAILURES >= FAILED_THRESHOLD )); then
  SAMPLE=$(echo "$RECENT_LOGS" | grep -E "Connection closed by authenticating user|Failed publickey|Invalid user.*ssh2" | tail -n 5)
  "$NOTIFY_SCRIPT" "🔑 SSH Key Auth Failures ($KEY_FAILURES attempts)" "$SAMPLE"
fi

# Check for any successful logins (for awareness)
SUCCESS_LOGINS=$(echo "$RECENT_LOGS" | grep -E "Accepted (password|publickey)" | wc -l | tr -d ' ')
if (( SUCCESS_LOGINS > 0 )); then
  SAMPLE=$(echo "$RECENT_LOGS" | grep -E "Accepted (password|publickey)" | tail -n 3)
  "$NOTIFY_SCRIPT" "✅ SSH Login Success ($SUCCESS_LOGINS logins)" "$SAMPLE"
fi
