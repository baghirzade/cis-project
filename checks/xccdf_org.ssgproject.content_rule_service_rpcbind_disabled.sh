#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_rpcbind_disabled"
TITLE="Ensure rpcbind.service is disabled and masked"

run() {
    # dpkg needed for applicability check
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system (dpkg missing)"
        return 0
    fi

    # linux-base must be installed for rule applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
       | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package not installed"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # If rpcbind service does not exist → OK
    if ! $SYSTEMCTL -q list-unit-files rpcbind.service 2>/dev/null; then
        echo "OK|$RULE_ID|rpcbind.service not present"
        return 0
    fi

    # Check disabled state
    if $SYSTEMCTL is-enabled rpcbind.service 2>/dev/null | grep -vq disabled; then
        echo "FAIL|$RULE_ID|rpcbind.service is not disabled"
        return 0
    fi

    # Check masked state
    if ! $SYSTEMCTL is-enabled rpcbind.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|rpcbind.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|rpcbind.service is disabled and masked"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
