#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-1.2"

check_pass_min_days() {
  local value
  value=$(grep -E '^PASS_MIN_DAYS' /etc/login.defs | awk '{print $2}' || echo "")

  if [[ -z "${value}" ]]; then
    log_warn "$CONTROL_ID: PASS_MIN_DAYS not set in /etc/login.defs (expected >= 1)"
    return 1
  fi

  if [[ "$value" -ge 1 ]]; then
    log_ok "$CONTROL_ID: PASS_MIN_DAYS ($value) is >= 1"
    return 0
  else
    log_warn "$CONTROL_ID: PASS_MIN_DAYS ($value) is < 1 (harden recommended)"
    return 1
  fi
}

check_pass_min_days
