#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-8.1"

check_auditd_installed() {
  if systemctl list-unit-files | grep -q '^auditd\.service'; then
    log_ok "$CONTROL_ID: auditd.service unit present"
  else
    log_warn "$CONTROL_ID: auditd.service not present (audit subsystem not installed)"
  fi

  if systemctl is-enabled auditd.service >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: auditd.service is enabled"
  else
    log_warn "$CONTROL_ID: auditd.service is not enabled"
  fi

  if systemctl is-active auditd.service >/dev/null 2>&1; then
    log_ok "$CONTROL_ID: auditd.service is running"
  else
    log_warn "$CONTROL_ID: auditd.service is not running"
  fi
}

check_auditd_installed
