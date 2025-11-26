#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-15.1"

check_aide_fim() {
  if dpkg -s aide >/dev/null 2>&1 || dpkg -s aide-common >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: AIDE package installed"
  else
    log_warn "$CONTROL_ID: AIDE package NOT installed"
  fi

  local db
  db=$(ls /var/lib/aide/aide.db* 2>/dev/null || true)
  if [[ -n "$db" ]]; then
    log_ok "$CONTROL_ID: AIDE database present: $(echo "$db" | tr '\n' ' ')"
  else
    log_warn "$CONTROL_ID: AIDE database not found under /var/lib/aide (initialize with aideinit)"
  fi

  # Just informational – cron/timer
  if systemctl list-timers | grep -q aide; then
    log_ok "$CONTROL_ID: AIDE systemd timer present"
  else
    log_info "$CONTROL_ID: No obvious AIDE timer/cron found (review scheduling manually)"
  fi
}

check_aide_fim
