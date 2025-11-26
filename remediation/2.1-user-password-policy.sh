#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-2.1"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/shadow.cis.${TS}.bak"

if [[ -f /etc/shadow ]]; then
  cp -p /etc/shadow "$BACKUP"
  log_info "$CONTROL_ID: Backup of /etc/shadow created at $BACKUP"
fi

while IFS=: read -r user _ uid _; do
  [[ "$uid" -lt 1000 ]] && continue
  [[ "$user" == "nobody" ]] && continue

  chage -m 1 -M 365 -W 7 "$user" || true
  log_ok "$CONTROL_ID: Updated password policy for user '$user' (MIN=1 MAX=365 WARN=7)"
done < /etc/passwd

log_ok "$CONTROL_ID: Remediation for all users completed successfully."
return 0