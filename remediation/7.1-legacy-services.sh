#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-7.1"

# Sadəcə nümunə – bəzi legacy xidmətləri disable
services=(telnet rsh-server rlogin-server tftp xinetd)

for s in "${services[@]}"; do
  if dpkg -s "$s" >/dev/null 2>&1; then
    log_info "$CONTROL_ID: Removing legacy service package $s"
    apt-get remove -y "$s" >/dev/null 2>&1 || true
  fi
done

log_ok "$CONTROL_ID: Basic legacy services removal attempted (telnet/rsh/rlogin/tftp/xinetd)"
exit 0