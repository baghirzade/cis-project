#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-14.1"

check_fail2ban_ssh() {
  if dpkg -s fail2ban >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: fail2ban package installed"
  else
    log_warn "$CONTROL_ID: fail2ban package NOT installed"
  fi

  if systemctl is-enabled fail2ban >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: fail2ban service enabled"
  else
    log_warn "$CONTROL_ID: fail2ban service not enabled"
  fi

  if systemctl is-active fail2ban >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: fail2ban service running"
  else
    log_warn "$CONTROL_ID: fail2ban service not running"
  fi

  # Check sshd jail
  if fail2ban-client status sshd >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: fail2ban sshd jail configured"
  else
    log_warn "$CONTROL_ID: fail2ban sshd jail not found (check /etc/fail2ban/jail*.conf)"
  fi
}

check_fail2ban_ssh
