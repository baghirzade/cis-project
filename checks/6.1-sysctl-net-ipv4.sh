#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-6.1"

check_sysctl() {
  log_info "$CONTROL_ID: Starting IPv4 sysctl audit"

  local KV=(
    "net.ipv4.ip_forward=0"
    "net.ipv4.conf.all.send_redirects=0"
    "net.ipv4.conf.default.send_redirects=0"
    "net.ipv4.conf.all.accept_redirects=0"
    "net.ipv4.conf.default.accept_redirects=0"
    "net.ipv4.conf.all.accept_source_route=0"
    "net.ipv4.conf.default.accept_source_route=0"
    "net.ipv4.conf.all.rp_filter=1"
    "net.ipv4.conf.default.rp_filter=1"
    "net.ipv4.tcp_syncookies=1"
  )

  local k expected current
  local all_ok=0

  for entry in "${KV[@]}"; do
    k=${entry%=*}
    expected=${entry#*=}
    current=$(sysctl -n "$k" 2>/dev/null || echo "<missing>")

    if [[ "$current" == "$expected" ]]; then
      log_ok "$CONTROL_ID: $k is correctly set to $current"
    else
      log_warn "$CONTROL_ID: $k is '$current' (expected: $expected)"
      all_ok=1
    fi
  done

  [[ "$all_ok" -eq 0 ]] || return 1
}

check_sysctl
