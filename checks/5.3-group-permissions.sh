#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-5.3"

check_group_permissions() {
  log_info "$CONTROL_ID: Checking /etc/group permissions and ownership"

  local owner group perms
  owner=$(stat -c '%U' /etc/group)
  group=$(stat -c '%G' /etc/group)
  perms=$(stat -c '%a' /etc/group)

  if [[ "$owner" == "root" && "$group" == "root" ]]; then
    log_ok "$CONTROL_ID: /etc/group ownership is correctly root:root"
  else
    log_warn "$CONTROL_ID: /etc/group ownership is $owner:$group (expected root:root)"
  fi

  if [[ "$perms" -le 644 ]]; then
    log_ok "$CONTROL_ID: /etc/group permissions are $perms (compliant: <= 644)"
  else
    log_warn "$CONTROL_ID: /etc/group permissions are $perms (too permissive, expected <= 644)"
  fi
}

check_group_permissions
