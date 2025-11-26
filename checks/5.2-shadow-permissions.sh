#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-5.2"

check_shadow_permissions() {
  log_info "$CONTROL_ID: Checking /etc/shadow permissions and ownership"

  local owner group perms
  owner=$(stat -c '%U' /etc/shadow)
  group=$(stat -c '%G' /etc/shadow)
  perms=$(stat -c '%a' /etc/shadow)

  if [[ "$owner" == "root" && "$group" =~ ^(shadow|root)$ ]]; then
    log_ok "$CONTROL_ID: /etc/shadow ownership is correctly $owner:$group"
  else
    log_warn "$CONTROL_ID: /etc/shadow ownership is $owner:$group (expected root:shadow or root:root)"
  fi

  if [[ "$perms" -le 640 ]]; then
    log_ok "$CONTROL_ID: /etc/shadow permissions are $perms (compliant: <= 640)"
  else
    log_warn "$CONTROL_ID: /etc/shadow permissions are $perms (too permissive, expected <= 640)"
  fi
}

check_shadow_permissions
