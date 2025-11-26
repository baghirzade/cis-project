#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-1.1"

check_pass_max_days() {
  local value
  value=$(grep -E '^PASS_MAX_DAYS' /etc/login.defs | awk '{print $2}' || echo "")

  if [[ -z "${value}" ]]; then
    log_warn "$CONTROL_ID: PASS_MAX_DAYS not set in /etc/login.defs (expected 365)"
    return 1
  fi

  if [[ "$value" -le 365 ]]; then
    log_ok "$CONTROL_ID: PASS_MAX_DAYS ($value) is <= 365"
    return 0
  else
    log_warn "$CONTROL_ID: PASS_MAX_DAYS ($value) is > 365 (harden recommended)"
    return 1
  fi
}

check_pass_max_days
