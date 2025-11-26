#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-1.5"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/default/useradd.cis.${TS}.bak"

if [[ -f /etc/default/useradd ]]; then
  cp -p /etc/default/useradd "$BACKUP"
  log_info "$CONTROL_ID: Backup created at $BACKUP"
fi

# default inactive 30 days
if grep -qE '^INACTIVE=' /etc/default/useradd; then
  sed -i 's/^INACTIVE=.*/INACTIVE=30/' /etc/default/useradd
else
  echo "INACTIVE=30" >> /etc/default/useradd
fi

log_ok "$CONTROL_ID: Set default INACTIVE=30 in /etc/default/useradd"

# optional: existing users – do not touch system accounts (<1000)
while IFS=: read -r user _ uid _; do
  [[ "$uid" -lt 1000 ]] && continue
  [[ "$user" == "nobody" ]] && continue
  chage --inactive 30 "$user" || true
  log_info "$CONTROL_ID: Set chage --inactive 30 for user '$user'"
done < /etc/passwd
log_ok "$CONTROL_ID: Set INACTIVE=30 for existing non-system users"
return 0