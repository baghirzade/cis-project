#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-5.1"

check_passwd_permissions() {
  log_info "$CONTROL_ID: Checking /etc/passwd permissions and ownership"

  local owner group perms
  owner=$(stat -c '%U' /etc/passwd)
  group=$(stat -c '%G' /etc/passwd)
  perms=$(stat -c '%a' /etc/passwd)

  if [[ "$owner" == "root" && "$group" == "root" ]]; then
    log_ok "$CONTROL_ID: /etc/passwd ownership is correctly root:root"
  else
    log_warn "$CONTROL_ID: /etc/passwd ownership is $owner:$group (expected root:root)"
  fi

  if [[ "$perms" -le 644 ]]; then
    log_ok "$CONTROL_ID: /etc/passwd permissions are $perms (compliant: <= 644)"
  else
    log_warn "$CONTROL_ID: /etc/passwd permissions are $perms (too permissive, expected <= 644)"
  fi
}

check_passwd_permissions
