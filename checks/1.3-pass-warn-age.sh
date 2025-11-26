#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-1.3"

check_pass_warn_age() {
  local value
  value=$(grep -E '^PASS_WARN_AGE' /etc/login.defs | awk '{print $2}' || echo "")

  if [[ -z "${value}" ]]; then
    log_warn "$CONTROL_ID: PASS_WARN_AGE not set in /etc/login.defs (expected >= 7)"
    return 1
  fi

  if [[ "$value" -ge 7 ]]; then
    log_ok "$CONTROL_ID: PASS_WARN_AGE ($value) is >= 7"
    return 0
  else
    log_warn "$CONTROL_ID: PASS_WARN_AGE ($value) is < 7 (harden recommended)"
    return 1
  fi
}

check_pass_warn_age
