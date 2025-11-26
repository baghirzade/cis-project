#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-12.1"

check_kernel_modules() {
  # Example: squashfs should be disabled
  local module="squashfs"
  local conf_files=(/etc/modprobe.d/*.conf)

  local disabled=0
  for f in "${conf_files[@]}"; do
    [[ ! -f "$f" ]] && continue
    if grep -Eq "^(install|blacklist)\s+${module}\b" "$f"; then
      disabled=1
      break
    fi
  done

  if lsmod | awk '{print $1}' | grep -q "^${module}$"; then
    log_warn "$CONTROL_ID: Module '$module' currently loaded (lsmod)"
  else
    log_ok "$CONTROL_ID: Module '$module' not loaded"
  fi

  if [[ "$disabled" -eq 1 ]]; then
    log_ok "$CONTROL_ID: Module '$module' is disabled via modprobe.d"
  else
    log_warn "$CONTROL_ID: Module '$module' is NOT disabled via modprobe.d (install /bin/true or blacklist)"
  fi
}

check_kernel_modules
