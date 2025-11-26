#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-13.1"

if ! command -v ufw >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing ufw"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y ufw
fi

ufw default deny incoming >/dev/null 2>&1 || true
ufw default allow outgoing >/dev/null 2>&1 || true

ufw enable <<<"y" >/dev/null 2>&1 || true

log_ok "$CONTROL_ID: UFW enabled (deny incoming, allow outgoing)"
return 0