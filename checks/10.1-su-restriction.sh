#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-10.1"

check_su_restriction() {
  if getent group wheel >/dev/null 2>&1 || getent group sudo >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: privilege group (wheel/sudo) exists"
  else
    log_warn "$CONTROL_ID: no wheel/sudo group found for su restriction"
  fi

  if grep -Eq 'auth\s+required\s+pam_wheel.so' /etc/pam.d/su 2>/dev/null; then
    log_ok "$CONTROL_ID: /etc/pam.d/su uses pam_wheel (su restricted to wheel/sudo)"
  else
    log_warn "$CONTROL_ID: /etc/pam.d/su does NOT use pam_wheel (su is not restricted)"
  fi
}

check_su_restriction
