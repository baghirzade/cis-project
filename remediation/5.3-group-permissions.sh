#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-5.3"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/group.cis.${TS}.bak"

cp -p /etc/group "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

chown root:root /etc/group
chmod 644 /etc/group

log_ok "$CONTROL_ID: Set /etc/group owner root:root and perms 644"
return 0