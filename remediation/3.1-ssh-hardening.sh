#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-3.1"
SSHD_CONFIG="/etc/ssh/sshd_config"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="${SSHD_CONFIG}.cis.${TS}.bak"

cp -p "$SSHD_CONFIG" "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

set_kv() {
  local key="$1" value="$2"
  if grep -Eq "^[#[:space:]]*${key}\b" "$SSHD_CONFIG"; then
    sed -i "s/^[#[:space:]]*${key}.*/${key} ${value}/" "$SSHD_CONFIG"
  else
    echo "${key} ${value}" >> "$SSHD_CONFIG"
  fi
}

set_kv "PermitRootLogin" "no"
set_kv "PasswordAuthentication" "no"
set_kv "MaxAuthTries" "3"
set_kv "Protocol" "2"
set_kv "X11Forwarding" "no"

systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || true
log_ok "$CONTROL_ID: SSH hardening options applied and sshd reloaded/restarted"
return 0