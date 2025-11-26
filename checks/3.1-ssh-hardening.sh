#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-3.1"
SSHD_CONFIG="/etc/ssh/sshd_config"

get_sshd_value() {
  local key="$1"
  awk -v k="$key" '
    $1 !~ /^#/ && tolower($1) == tolower(k) {print $2}
  ' "$SSHD_CONFIG" | tail -n1
}

check_ssh_hardening() {
  log_info "$CONTROL_ID: Starting SSH hardening audit"

  local val
  val=$(get_sshd_value "PermitRootLogin")
  if [[ "$val" == "no" ]]; then
    log_ok "$CONTROL_ID: PermitRootLogin is correctly set to 'no'"
  else
    log_warn "$CONTROL_ID: PermitRootLogin is '${val:-<unset>}' (expected: no)"
  fi

  val=$(get_sshd_value "PasswordAuthentication")
  if [[ "$val" == "no" ]]; then
    log_ok "$CONTROL_ID: PasswordAuthentication is correctly set to 'no'"
  else
    log_warn "$CONTROL_ID: PasswordAuthentication is '${val:-<unset>}' (expected: no)"
  fi

  val=$(get_sshd_value "MaxAuthTries")
  if [[ "$val" == "3" ]]; then
    log_ok "$CONTROL_ID: MaxAuthTries is correctly set to '3'"
  else
    log_warn "$CONTROL_ID: MaxAuthTries is '${val:-<unset>}' (expected: 3)"
  fi

  val=$(get_sshd_value "Protocol")
  if [[ "$val" == "2" ]]; then
    log_ok "$CONTROL_ID: Protocol is correctly set to '2'"
  else
    log_warn "$CONTROL_ID: Protocol is '${val:-<unset>}' (expected: 2)"
  fi

  val=$(get_sshd_value "X11Forwarding")
  if [[ "$val" == "no" ]]; then
    log_ok "$CONTROL_ID: X11Forwarding is correctly set to 'no'"
  else
    log_warn "$CONTROL_ID: X11Forwarding is '${val:-<unset>}' (expected: no)"
  fi
}

check_ssh_hardening
