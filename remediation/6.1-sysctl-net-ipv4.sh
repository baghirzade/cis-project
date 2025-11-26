#!/usr/bin/env bash
set -euo pipefail
CONTROL_ID="CIS-EXAMPLE-6.1"

TS="$(date +%Y%m%d-%H%M%S)"
BACKUP="/etc/sysctl.conf.cis.${TS}.bak"

cp -p /etc/sysctl.conf "$BACKUP"
log_info "$CONTROL_ID: Backup created at $BACKUP"

set_sysctl() {
  local key="$1" val="$2"
  if grep -qE "^[[:space:]]*${key}[[:space:]]*=" /etc/sysctl.conf; then
    sed -i "s/^[[:space:]]*${key}[[:space:]]*=.*/${key} = ${val}/" /etc/sysctl.conf
  else
    echo "${key} = ${val}" >> /etc/sysctl.conf
  fi
  sysctl -w "${key}=${val}" >/dev/null 2>&1 || true
}

set_sysctl "net.ipv4.ip_forward" 0
set_sysctl "net.ipv4.conf.all.send_redirects" 0
set_sysctl "net.ipv4.conf.default.send_redirects" 0
set_sysctl "net.ipv4.conf.all.accept_redirects" 0
set_sysctl "net.ipv4.conf.default.accept_redirects" 0
set_sysctl "net.ipv4.conf.all.accept_source_route" 0
set_sysctl "net.ipv4.conf.default.accept_source_route" 0
set_sysctl "net.ipv4.conf.all.rp_filter" 1
set_sysctl "net.ipv4.conf.default.rp_filter" 1
set_sysctl "net.ipv4.tcp_syncookies" 1

sysctl -p >/dev/null 2>&1 || true
log_ok "$CONTROL_ID: IPv4 sysctl hardening applied"
return 0