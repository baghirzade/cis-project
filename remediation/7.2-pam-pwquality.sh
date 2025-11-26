#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-7.2"

PWQ_CONF="/etc/security/pwquality.conf"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="${PWQ_CONF}.cis.${TS}.bak"

if [[ -f "$PWQ_CONF" ]]; then
  cp -p "$PWQ_CONF" "$BACKUP"
  log_info "$CONTROL_ID: Backup created at $BACKUP"
else
  touch "$PWQ_CONF"
fi

set_kv() {
  local key="$1" val="$2"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" "$PWQ_CONF"; then
    sed -i "s/^[[:space:]]*${key}[[:space:]]*=.*/${key} = ${val}/" "$PWQ_CONF"
  else
    echo "${key} = ${val}" >> "$PWQ_CONF"
  fi
}

set_kv "minlen" "14"
set_kv "dcredit" "-1"
set_kv "ucredit" "-1"
set_kv "lcredit" "-1"
set_kv "ocredit" "-1"

log_ok "$CONTROL_ID: pwquality.conf updated (minlen=14, d/u/l/ocredit=-1)"
return 0