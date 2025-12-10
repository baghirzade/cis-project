#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_bluetooth_disabled"
TITLE="Ensure bluetooth service is disabled and masked"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1 || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    local SYSTEMCTL_EXEC='/usr/bin/systemctl'
    local RETURN_CODE=0
    
    # 1. Check if bluetooth.service is masked
    if ! "$SYSTEMCTL_EXEC" is-enabled bluetooth.service | grep -q 'masked'; then
        echo "WARN|$RULE_ID|bluetooth.service is not masked."
        RETURN_CODE=1
    fi
    
    # 2. Check if bluetooth.service is stopped/inactive (runtime check)
    if "$SYSTEMCTL_EXEC" is-active bluetooth.service &>/dev/null; then
        echo "WARN|$RULE_ID|bluetooth.service is currently running/active."
        RETURN_CODE=1
    fi

    # 3. Check for bluetooth.socket (if unit file exists)
    if "$SYSTEMCTL_EXEC" -q list-unit-files bluetooth.socket; then
        if ! "$SYSTEMCTL_EXEC" is-enabled bluetooth.socket | grep -q 'masked'; then
            echo "WARN|$RULE_ID|bluetooth.socket is present but not masked."
            RETURN_CODE=1
        fi
        
        # Check if socket is stopped/inactive
        if "$SYSTEMCTL_EXEC" is-active bluetooth.socket &>/dev/null; then
            echo "WARN|$RULE_ID|bluetooth.socket is currently active."
            RETURN_CODE=1
        fi
    fi

    if [ "$RETURN_CODE" -eq 0 ]; then
        echo "OK|$RULE_ID|bluetooth.service and bluetooth.socket (if present) are masked and inactive."
    fi

    return $RETURN_CODE
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
