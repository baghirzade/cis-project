#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-2.4"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/sudoers.cis.${TS}.bak"

cp -p /etc/sudoers "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

LOGFILE="/var/log/sudo.log"
touch "$LOGFILE"
chmod 600 "$LOGFILE"
chown root:root "$LOGFILE"

if grep -Eq '^[[:space:]]*Defaults[[:space:]]+.*logfile=' /etc/sudoers; then
  sed -i 's/^\s*Defaults\s\+.*logfile=.*/Defaults logfile="\/var\/log\/sudo.log"/' /etc/sudoers
else
  echo 'Defaults logfile="/var/log/sudo.log"' >> /etc/sudoers
fi

log_ok "$CONTROL_ID: Configured sudo logfile=/var/log/sudo.log"
visudo -c >/dev/null 2>&1 || log_warn "$CONTROL_ID: visudo -c reported issues – review /etc/sudoers"
return 0