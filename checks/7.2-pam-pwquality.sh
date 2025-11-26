#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-7.2"
PWQ_CONF="/etc/security/pwquality.conf"

check_pam_pwquality() {
  if [[ ! -f "$PWQ_CONF" ]]; then
    log_warn "$CONTROL_ID: $PWQ_CONF not found (pwquality not configured)"
    return 1
  fi

  local ok=0

  # minlen >= 14
  if grep -Eq '^\s*minlen\s*=\s*(1[4-9]|[2-9][0-9])' "$PWQ_CONF"; then
    log_ok "$CONTROL_ID: minlen is set to >= 14"
    ok=$((ok+1))
  else
    log_warn "$CONTROL_ID: minlen not set to >= 14"
  fi

  # negative d/u/l/o credit – “must contain”
  if grep -Eq '^\s*dcredit\s*=\s*-[1-9]' "$PWQ_CONF"; then
    log_ok "$CONTROL_ID: dcredit (digits) set to negative"
    ok=$((ok+1))
  else
    log_warn "$CONTROL_ID: dcredit not enforced as negative"
  fi

  if grep -Eq '^\s*ucredit\s*=\s*-[1-9]' "$PWQ_CONF"; then
    log_ok "$CONTROL_ID: ucredit (upper) set to negative"
    ok=$((ok+1))
  else
    log_warn "$CONTROL_ID: ucredit not enforced as negative"
  fi

  if grep -Eq '^\s*lcredit\s*=\s*-[1-9]' "$PWQ_CONF"; then
    log_ok "$CONTROL_ID: lcredit (lower) set to negative"
    ok=$((ok+1))
  else
    log_warn "$CONTROL_ID: lcredit not enforced as negative"
  fi

  if grep -Eq '^\s*ocredit\s*=\s*-[1-9]' "$PWQ_CONF"; then
    log_ok "$CONTROL_ID: ocredit (special) set to negative"
    ok=$((ok+1))
  else
    log_warn "$CONTROL_ID: ocredit not enforced as negative"
  fi

  if [[ "$ok" -ge 3 ]]; then
    log_ok "$CONTROL_ID: pwquality complexity mostly compliant (manual review recommended)"
  fi
}

check_pam_pwquality
