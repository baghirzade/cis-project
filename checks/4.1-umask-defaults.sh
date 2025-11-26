#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-4.1"

check_umask_defaults() {
  log_info "$CONTROL_ID: Starting UMASK audit"

  local login_def_umask
  login_def_umask=$(grep -E '^UMASK' /etc/login.defs | awk '{print $2}' || true)

  if [[ "$login_def_umask" == "027" ]]; then
    log_ok "$CONTROL_ID: UMASK in /etc/login.defs is correctly set to 027"
  else
    log_warn "$CONTROL_ID: UMASK in /etc/login.defs is '$login_def_umask' (expected: 027)"
  fi

  local profile_umask
  profile_umask=$(grep -E '^[[:space:]]*umask[[:space:]]+([0-7]{3})' /etc/profile | awk '{print $2}' | tail -n1 || true)

  if [[ "$profile_umask" == "027" ]]; then
    log_ok "$CONTROL_ID: umask in /etc/profile is correctly set to 027"
  else
    log_warn "$CONTROL_ID: umask in /etc/profile is '$profile_umask' (expected: 027)"
  fi
}

check_umask_defaults
