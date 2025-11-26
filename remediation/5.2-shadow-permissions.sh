#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-5.2"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/shadow.cis.${TS}.bak"

cp -p /etc/shadow "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

chown root:shadow /etc/shadow || chown root:root /etc/shadow
chmod 640 /etc/shadow

log_ok "$CONTROL_ID: Set /etc/shadow owner root:shadow and perms 640"
return 0