#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-2.3"

check_sudo_pty() {
  local sudoers_files=("/etc/sudoers" /etc/sudoers.d/*)
  local found=0

  for f in "${sudoers_files[@]}"; do
    [[ ! -f "$f" ]] && continue
    if grep -Eq '^[[:space:]]*Defaults[[:space:]]+.*use_pty' "$f"; then
      log_ok "$CONTROL_ID: use_pty set in $f"
      found=1
    fi
  done

  if [[ "$found" -eq 0 ]]; then
    log_warn "$CONTROL_ID: use_pty not set in sudoers (recommended: Defaults use_pty)"
  fi
}

check_sudo_pty
