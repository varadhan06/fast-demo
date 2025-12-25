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
