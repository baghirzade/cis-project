#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-9.1"

check_login_banners() {
  local files=("/etc/motd" "/etc/issue" "/etc/issue.net")

  for f in "${files[@]}"; do
    if [[ -f "$f" ]]; then
      local owner group perms
      owner=$(stat -c '%U' "$f")
      group=$(stat -c '%G' "$f")
      perms=$(stat -c '%a' "$f")

      if [[ "$owner" == "root" && "$group" == "root" && "$perms" -le 644 ]]; then
        log_ok "$CONTROL_ID: $f permissions are secure ($perms, $owner:$group)"
      else
        log_warn "$CONTROL_ID: $f permissions are $perms, $owner:$group (expected <=644 root:root)"
      fi
    else
      log_warn "$CONTROL_ID: $f is missing (review banner requirements)"
    fi
  done
}

check_login_banners
