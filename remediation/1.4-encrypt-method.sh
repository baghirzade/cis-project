#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-1.4"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/login.defs.cis.${TS}.bak"

if [[ -f /etc/login.defs ]]; then
  cp -p /etc/login.defs "$BACKUP"
  log_info "$CONTROL_ID: Backup created at $BACKUP"
fi

# SHA-512
if grep -qE '^ENCRYPT_METHOD' /etc/login.defs; then
  sed -i 's/^ENCRYPT_METHOD.*/ENCRYPT_METHOD SHA512/' /etc/login.defs
else
  echo "ENCRYPT_METHOD SHA512" >> /etc/login.defs
fi

log_ok "$CONTROL_ID: Set ENCRYPT_METHOD to SHA512 in /etc/login.defs"
return 0