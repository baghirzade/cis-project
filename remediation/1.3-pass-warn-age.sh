#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-1.3"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/login.defs.cis.${TS}.bak"

if [[ -f /etc/login.defs ]]; then
  cp -p /etc/login.defs "$BACKUP"
  log_info "$CONTROL_ID: Backup created at $BACKUP"
fi

if grep -qE '^PASS_WARN_AGE' /etc/login.defs; then
  sed -i 's/^PASS_WARN_AGE.*/PASS_WARN_AGE   7/' /etc/login.defs
else
  echo "PASS_WARN_AGE   7" >> /etc/login.defs
fi

log_ok "$CONTROL_ID: Set PASS_WARN_AGE to 7 in /etc/login.defs"
return 0