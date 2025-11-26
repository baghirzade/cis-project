#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-2.2"

if ! command -v sudo >/dev/null 2>&1; then
  log_info "$CONTROL_ID: Installing sudo package"
  apt-get update -y >/dev/null 2>&1 || true
  apt-get install -y sudo
else
  log_info "$CONTROL_ID: sudo already installed"
fi

log_ok "$CONTROL_ID: sudo package present"
