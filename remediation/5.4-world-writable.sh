#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-5.4"

log_info "$CONTROL_ID: Remediating world-writable files (will remove global write bit)"

WW_LIST=$(find / -xdev -type f -perm -0002 \
  ! -path '/proc/*' ! -path '/sys/*' ! -path '/dev/*' 2>/dev/null || true)

if [[ -z "$WW_LIST" ]]; then
  log_ok "$CONTROL_ID: No world-writable files to remediate"
  exit 0
fi

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  chmod o-w "$f" || true
  log_info "$CONTROL_ID: Removed world-write from $f"
done <<< "$WW_LIST"

log_ok "$CONTROL_ID: World-writable remediation completed (permissions tightened)"
exit 0