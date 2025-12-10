#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_httpd_disabled"
TITLE="Ensure apache2.service is disabled and masked"

run() {

    # dpkg required
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found (non-Debian or non-Ubuntu)"
        return 0
    fi

    # Rule applies only if linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # If apache2.service does not exist → OK
    if ! $SYSTEMCTL -q list-unit-files apache2.service >/dev/null 2>&1; then
        echo "OK|$RULE_ID|apache2.service not present"
        return 0
    fi

    enabled=$($SYSTEMCTL is-enabled apache2.service 2>/dev/null || echo "unknown")
    active=$($SYSTEMCTL is-active apache2.service 2>/dev/null || echo "unknown")
    masked=$($SYSTEMCTL is-enabled apache2.service 2>/dev/null | grep -q masked && echo "yes" || echo "no")

    failures=()

    # Required: disabled
    if [[ "$enabled" != "disabled" && "$enabled" != "masked" ]]; then
        failures+=("enabled=$enabled")
    fi

    # Required: inactive
    if [[ "$active" != "inactive" && "$active" != "failed" ]]; then
        failures+=("active=$active")
    fi

    # Required: masked
    mask_state=$($SYSTEMCTL show -p UnitFileState apache2.service 2>/dev/null | cut -d= -f2)
    if [[ "$mask_state" != "masked" ]]; then
        failures+=("mask_state=$mask_state")
    fi

    if [[ ${#failures[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|apache2.service is disabled and masked"
        return 0
    fi

    echo "WARN|$RULE_ID|Non-compliant states: ${failures[*]}"
    return 1
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && run