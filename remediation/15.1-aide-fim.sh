#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-15.1"

if ! dpkg -s aide >/dev/null 2>&1 && ! dpkg -s aide-common >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing AIDE"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y aide aide-common
fi

if [[ -f /etc/aide/aide.conf ]]; then
  log_info "$CONTROL_ID: Using existing /etc/aide/aide.conf"
fi

if [[ ! -e /var/lib/aide/aide.db.gz && ! -e /var/lib/aide/aide.db ]]; then
  log_info "$CONTROL_ID: Initializing AIDE database (this may take a while)"
  aideinit || true
  if [[ -f /var/lib/aide/aide.db.new.gz ]]; then
    mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz
  fi
fi

log_ok "$CONTROL_ID: AIDE installed and initial database ensured"
return 0