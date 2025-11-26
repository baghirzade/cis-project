#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-3.2"
SSHD_CONFIG="/etc/ssh/sshd_config"

get_sshd_value() {
  local key="$1"
  awk -v k="$key" '
    $1 !~ /^#/ && tolower($1) == tolower(k) {print $2}
  ' "$SSHD_CONFIG" | tail -n1
}

check_ssh_idle_timeout() {
  local interval count
  interval=$(get_sshd_value "ClientAliveInterval")
  count=$(get_sshd_value "ClientAliveCountMax")

  if [[ -z "$interval" || -z "$count" ]]; then
    log_warn "$CONTROL_ID: ClientAliveInterval/ClientAliveCountMax not fully configured (expected idle timeout)."
    return 1
  fi

  if [[ "$interval" -le 300 && "$count" -le 3 ]]; then
    log_ok "$CONTROL_ID: SSH idle timeout configured (ClientAliveInterval=$interval, CountMax=$count)"
  else
    log_warn "$CONTROL_ID: SSH idle timeout too lax (ClientAliveInterval=$interval, CountMax=$count; expected <=300s, <=3)"
  fi
}

check_ssh_idle_timeout
