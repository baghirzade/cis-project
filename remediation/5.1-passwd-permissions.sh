#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-5.1"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/passwd.cis.${TS}.bak"

cp -p /etc/passwd "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

chown root:root /etc/passwd
chmod 644 /etc/passwd

log_ok "$CONTROL_ID: Set /etc/passwd owner root:root and perms 644"
return 0