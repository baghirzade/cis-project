#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_nfs_disabled"
TITLE="Ensure nfs-server.service is disabled and masked"

run() {

    # Check applicability
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian system)"
        return 0
    fi

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # Service missing → OK
    if ! $SYSTEMCTL -q list-unit-files nfs-server.service >/dev/null 2>&1; then
        echo "OK|$RULE_ID|nfs-server.service not present"
        return 0
    fi

    failures=()

    # Disabled?
    enabled_state=$($SYSTEMCTL is-enabled nfs-server.service 2>/dev/null || echo "unknown")
    if [[ "$enabled_state" != "disabled" && "$enabled_state" != "masked" ]]; then
        failures+=("enabled=$enabled_state")
    fi

    # Inactive?
    active_state=$($SYSTEMCTL is-active nfs-server.service 2>/dev/null || echo "unknown")
    if [[ "$active_state" != "inactive" && "$active_state" != "failed" ]]; then
        failures+=("active=$active_state")
    fi

    # Masked?
    mask_state=$($SYSTEMCTL show -p UnitFileState nfs-server.service 2>/dev/null | cut -d= -f2)
    if [[ "$mask_state" != "masked" ]]; then
        failures+=("mask_state=$mask_state")
    fi

    # Decide final result
    if [[ ${#failures[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|nfs-server.service is disabled and masked"
        return 0
    fi

    echo "WARN|$RULE_ID|Non-compliant: ${failures[*]}"
    return 1
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && run
