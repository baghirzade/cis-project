#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-2.4"

check_sudo_logging() {
  local sudoers_files=("/etc/sudoers" /etc/sudoers.d/*)
  local logfile_found=0
  local syslog_found=0

  for f in "${sudoers_files[@]}"; do
    [[ ! -f "$f" ]] && continue
    if grep -Eq '^[[:space:]]*Defaults[[:space:]]+.*logfile=' "$f"; then
      log_ok "$CONTROL_ID: explicit sudo logfile configured in $f"
      logfile_found=1
    fi
    if grep -Eq '^[[:space:]]*Defaults[[:space:]]+.*syslog' "$f"; then
      log_ok "$CONTROL_ID: sudo syslog logging configured in $f"
      syslog_found=1
    fi
  done

  if [[ "$logfile_found" -eq 0 && "$syslog_found" -eq 0 ]]; then
    log_warn "$CONTROL_ID: No explicit sudo logging (logfile or syslog) configured in sudoers"
  fi
}

check_sudo_logging
