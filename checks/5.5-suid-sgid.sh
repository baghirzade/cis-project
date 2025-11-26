#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-5.5"

check_suid_sgid() {
  log_info "$CONTROL_ID: Scanning for SUID/SGID binaries (this may take some time)"

  local bins
  bins=$(find / -xdev \
    \( -perm -4000 -o -perm -2000 \) \
    -type f \
    ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' 2>/dev/null || true)

  if [[ -z "$bins" ]]; then
    log_ok "$CONTROL_ID: No SUID/SGID binaries found (unexpected for most systems, please verify)"
  else
    log_info "$CONTROL_ID: SUID/SGID binaries list:"
    while IFS= read -r b; do
      [[ -z "$b" ]] && continue
      log_info "$CONTROL_ID:   $b"
    done <<< "$bins"
    log_ok "$CONTROL_ID: SUID/SGID audit completed (manual review recommended)."
  fi
}

check_suid_sgid
