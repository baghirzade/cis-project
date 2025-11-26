#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-2.2"

check_sudo_installed() {
  if command -v sudo >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: sudo package is installed"
  else
    log_warn "$CONTROL_ID: sudo package is NOT installed"
  fi
}

check_sudo_installed
