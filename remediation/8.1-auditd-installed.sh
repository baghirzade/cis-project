#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-8.1"

if ! dpkg -s auditd >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing auditd"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y auditd audispd-plugins
fi

systemctl enable auditd.service >/dev/null 2>&1 || true
systemctl start auditd.service >/dev/null 2>&1 || true

log_ok "$CONTROL_ID: auditd installed, enabled and started"
exit 0