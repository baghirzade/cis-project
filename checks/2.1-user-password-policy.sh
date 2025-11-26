#!/usr/bin/env bash
set -euo pipefail

CONTROL_ID="CIS-EXAMPLE-2.1"

check_user_password_policy() {
  log_info "$CONTROL_ID: Starting user password policy check (via chage)"

  local noncompliant=0
  local user uid min max warn

  while IFS=: read -r user _ uid _; do
    [[ "$uid" -lt 1000 ]] && continue
    [[ "$user" == "nobody" ]] && continue

    read -r _ min <<<"$(chage -l "$user" | awk -F': ' '/Minimum.*days/ {print $2}')"
    read -r _ max <<<"$(chage -l "$user" | awk -F': ' '/Maximum.*days/ {print $2}')"
    read -r _ warn <<<"$(chage -l "$user" | awk -F': ' '/warning/ {print $2}')"

    min=${min:-0}
    max=${max:-99999}
    warn=${warn:-0}

    if [[ "$min" -ge 1 && "$max" -le 365 && "$warn" -ge 7 ]]; then
      log_ok "$CONTROL_ID: User '$user' password policy is compliant (MIN=$min MAX=$max WARN=$warn)"
    else
      log_warn "$CONTROL_ID: User '$user' password policy NOT compliant (MIN=$min MAX=$max WARN=$warn)"
      noncompliant=$((noncompliant+1))
    fi
  done < /etc/passwd

  if [[ "$noncompliant" -eq 0 ]]; then
    log_ok "$CONTROL_ID: All checked users are compliant."
  else
    log_warn "$CONTROL_ID: $noncompliant user(s) with non-compliant password policy."
  fi
}

check_user_password_policy
