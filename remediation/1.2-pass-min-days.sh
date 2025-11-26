#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-1.2"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/login.defs.cis.${TS}.bak"

if [[ -f /etc/login.defs ]]; then
  cp -p /etc/login.defs "$BACKUP"
  log_info "$CONTROL_ID: Backup created at $BACKUP"
fi

if grep -qE '^PASS_MIN_DAYS' /etc/login.defs; then
  sed -i 's/^PASS_MIN_DAYS.*/PASS_MIN_DAYS   1/' /etc/login.defs
else
  echo "PASS_MIN_DAYS   1" >> /etc/login.defs
fi

log_ok "$CONTROL_ID: Set PASS_MIN_DAYS to 1 in /etc/login.defs"
return 0