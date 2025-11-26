#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-11.1"

check_unattended_upgrades() {
  if dpkg -s unattended-upgrades >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: unattended-upgrades package is installed"
  else
    log_warn "$CONTROL_ID: unattended-upgrades package is NOT installed"
  fi

  local conf="/etc/apt/apt.conf.d/20auto-upgrades"
  if [[ -f "$conf" ]]; then
    if grep -Eq 'APT::Periodic::Unattended-Upgrade\s*"1";' "$conf"; then
      log_ok "$CONTROL_ID: Unattended-Upgrade is enabled in $conf"
    else
      log_warn "$CONTROL_ID: Unattended-Upgrade not enabled in $conf"
    fi
  else
    log_warn "$CONTROL_ID: $conf not found (auto upgrades not configured)"
  fi
}

check_unattended_upgrades
