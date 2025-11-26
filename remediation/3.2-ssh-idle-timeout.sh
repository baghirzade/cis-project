#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-3.2"
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

set_kv "ClientAliveInterval" "300"
set_kv "ClientAliveCountMax" "3"

systemctl reload sshd 2>/dev/null || systemctl restart sshd 2>/dev/null || true
log_ok "$CONTROL_ID: SSH idle timeout configured (ClientAliveInterval=300, CountMax=3)"
return 0