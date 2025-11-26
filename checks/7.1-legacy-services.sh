#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-7.1"

PWQ_CONF="/etc/security/pwquality.conf"

check_pam_pwquality() {
  if [[ ! -f "$PWQ_CONF" ]]; then
    log_warn "$CONTROL_ID: $PWQ_CONF not found (pwquality not configured)"
    return 1
  fi

  local ok=0

  grep -Eq '^\s*minlen\s*=\s*([1-9][0-9]+)' "$PWQ_CONF" && ok=$((ok+1)) || \
    log_warn "$CONTROL_ID: minlen not set (recommended >= 14)"

  grep -Eq '^\s*dcredit\s*=\s*-' "$PWQ_CONF" && ok=$((ok+1)) || \
    log_warn "$CONTROL_ID: dcredit (digits) not set to negative"

  grep -Eq '^\s*ucredit\s*=\s*-' "$PWQ_CONF" && ok=$((ok+1)) || \
    log_warn "$CONTROL_ID: ucredit (uppercase) not set to negative"

  grep -Eq '^\s*lcredit\s*=\s*-' "$PWQ_CONF" && ok=$((ok+1)) || \
    log_warn "$CONTROL_ID: lcredit (lowercase) not set to negative"

  grep -Eq '^\s*ocredit\s*=\s*-' "$PWQ_CONF" && ok=$((ok+1)) || \
    log_warn "$CONTROL_ID: ocredit (special) not set to negative"

  if [[ "$ok" -ge 3 ]]; then
    log_ok "$CONTROL_ID: pwquality.conf has several complexity settings configured (manual review recommended)"
  fi
}

check_pam_pwquality
