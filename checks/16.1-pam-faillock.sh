#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-16.1"

check_pam_faillock() {
  local files=(/etc/pam.d/common-auth /etc/pam.d/system-auth /etc/pam.d/password-auth)

  local present=0
  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    if grep -Eq 'pam_(tally2|faillock)\.so' "$f"; then
      log_ok "$CONTROL_ID: $f contains pam_tally2/pam_faillock"
      present=1
    fi
  done

  if [[ "$present" -eq 0 ]]; then
    log_warn "$CONTROL_ID: No pam_tally2 / pam_faillock configuration found in standard PAM auth files"
  fi

  # Very simple parameter check example (Ubuntu pam_faillock.d if present)
  if [[ -d /etc/security ]]; then
    if grep -Riq 'deny\s*=\s*[345]' /etc/security 2>/dev/null; then
      log_ok "$CONTROL_ID: Some faillock deny parameter (<=5) configured in /etc/security"
    else
      log_info "$CONTROL_ID: Could not confirm faillock deny parameter; manual review recommended"
    fi
  fi
}

check_pam_faillock
