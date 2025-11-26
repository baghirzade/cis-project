#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-2.3"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/sudoers.cis.${TS}.bak"

cp -p /etc/sudoers "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

if grep -Eq '^[[:space:]]*Defaults[[:space:]]+.*use_pty' /etc/sudoers; then
  log_info "$CONTROL_ID: Defaults use_pty already present in /etc/sudoers"
else
  echo "Defaults use_pty" >> /etc/sudoers
  log_ok "$CONTROL_ID: Added 'Defaults use_pty' to /etc/sudoers"
fi

visudo -c >/dev/null 2>&1 || log_warn "$CONTROL_ID: visudo -c reported issues – review /etc/sudoers"
return 0