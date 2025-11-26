#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-1.4"

check_inactive_lock() {
  local def_inactive
  def_inactive=$(useradd -D | awk -F= '/INACTIVE/ {print $2}')

  if [[ -z "$def_inactive" || "$def_inactive" -lt 0 ]]; then
    log_warn "$CONTROL_ID: Default INACTIVE is not set or -1 (no lock). Expected <= 30 days."
  else
    if [[ "$def_inactive" -le 30 ]]; then
      log_ok "$CONTROL_ID: Default INACTIVE ($def_inactive) <= 30 days"
    else
      log_warn "$CONTROL_ID: Default INACTIVE ($def_inactive) > 30 days (harden recommended)"
    fi
  fi

  # Optional: sample of existing users – informational only
  local user
  while IFS=: read -r user _ uid _; do
    [[ "$uid" -lt 1000 ]] && continue
    local u_inactive
    u_inactive=$(chage -l "$user" | awk -F': ' '/Account inactive/ {print $2}')
    log_info "$CONTROL_ID: User '$user' Account inactive: $u_inactive"
  done < /etc/passwd
}

check_inactive_lock
