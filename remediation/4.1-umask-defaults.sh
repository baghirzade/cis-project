#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-4.1"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_LOGIN="/etc/login.defs.cis.${TS}.bak"
BACKUP_PROFILE="/etc/profile.cis.${TS}.bak"

cp -p /etc/login.defs "$BACKUP_LOGIN"
cp -p /etc/profile "$BACKUP_PROFILE"
log_info "$CONTROL_ID: Backups created for /etc/login.defs and /etc/profile"

if grep -qE '^UMASK' /etc/login.defs; then
  sed -i 's/^UMASK.*/UMASK 027/' /etc/login.defs
else
  echo "UMASK 027" >> /etc/login.defs
fi

if grep -Eq '^[[:space:]]*umask[[:space:]]+[0-7]{3}' /etc/profile; then
  sed -i 's/^[[:space:]]*umask[[:space:]]\+[0-7]\{3\}/umask 027/' /etc/profile
else
  echo "umask 027" >> /etc/profile
fi

log_ok "$CONTROL_ID: Set UMASK/POSIX umask to 027 in login.defs and profile"
return 0