#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-13.1"

check_ufw_basic() {
  if ! command -v ufw >/dev/null 2>&1; then
    log_warn "$CONTROL_ID: ufw not installed (using other firewall stack?)"
    return 1
  fi

  local status
  status=$(ufw status | head -n1)
  if grep -qi "Status: active" <<<"$status"; then
    log_ok "$CONTROL_ID: UFW is active"
  else
    log_warn "$CONTROL_ID: UFW is not active"
  fi

  local incoming outgoing
  incoming=$(ufw status verbose 2>/dev/null | awk -F: '/Default:/{gsub(/ /,"",$2); print $2}' | sed -n '1p')
  outgoing=$(ufw status verbose 2>/dev/null | awk -F: '/Default:/{gsub(/ /,"",$2); print $2}' | sed -n '2p')

  # Expected: deny (incoming), allow (outgoing)
  if grep -qi "deny(incoming)" <<<"$incoming"; then
    log_ok "$CONTROL_ID: Default incoming policy is deny"
  else
    log_warn "$CONTROL_ID: Default incoming policy not deny (found: ${incoming:-<unknown>})"
  fi

  if grep -qi "allow(outgoing)" <<<"$outgoing"; then
    log_ok "$CONTROL_ID: Default outgoing policy is allow"
  else
    log_warn "$CONTROL_ID: Default outgoing policy not allow (found: ${outgoing:-<unknown>})"
  fi
}

check_ufw_basic
