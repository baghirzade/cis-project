#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-10.1"

groupadd -f wheel || true

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/pam.d/su.cis.${TS}.bak"
cp -p /etc/pam.d/su "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

if grep -Eq 'pam_wheel.so' /etc/pam.d/su; then
  sed -i 's/^\s*auth\s\+required\s\+pam_wheel.so.*/auth       required   pam_wheel.so use_uid group=wheel/' /etc/pam.d/su
else
  echo "auth       required   pam_wheel.so use_uid group=wheel" >> /etc/pam.d/su
fi

log_ok "$CONTROL_ID: su restricted to wheel group via pam_wheel"
return 0