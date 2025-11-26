#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-5.4"

check_world_writable() {
  log_info "$CONTROL_ID: Scanning for world-writable files (this may take some time)"

  local bad
  bad=$(find / -xdev \
    -type f -perm -0002 \
    ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' 2>/dev/null || true)

  if [[ -z "$bad" ]]; then
    log_ok "$CONTROL_ID: No world-writable regular files found (excluding system pseudo-filesystems)"
  else
    log_warn "$CONTROL_ID: World-writable files found:"
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      log_warn "$CONTROL_ID:   $f"
    done <<< "$bad"
  fi
}

check_world_writable
