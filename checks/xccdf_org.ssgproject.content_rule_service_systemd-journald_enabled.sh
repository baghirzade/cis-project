#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_systemd-journald_enabled"
TITLE="systemd-journald.service must be enabled"

run() {
    # Only Debian/Ubuntu (per remediation guard)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Follow remediation guard: require linux-base installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package not installed (rule not applicable)"
        return 0
    fi

    # Require systemd
    if ! command -v systemctl >/dev/null 2>&1 || [ ! -d /run/systemd/system ]; then
        echo "NOTAPPL|$RULE_ID|systemd is not the init system (rule not applicable)"
        return 0
    fi

    local svc="systemd-journald.service"
    local status_enabled status_active

    status_enabled="$(systemctl is-enabled "$svc" 2>&1 || true)"
    status_active="$(systemctl is-active "$svc" 2>&1 || true)"

    if [[ "$status_enabled" == "masked" ]]; then
        echo "WARN|$RULE_ID|$svc is masked"
        return 0
    fi

    if [[ "$status_enabled" == "enabled" && "$status_active" == "active" ]]; then
        echo "OK|$RULE_ID|$svc is enabled and active"
    else
        echo "WARN|$RULE_ID|$svc is not properly enabled/active (enabled: $status_enabled, active: $status_active)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
