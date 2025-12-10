#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_dhcpd6_disabled"
TITLE="Ensure isc-dhcp-server6 service is disabled and masked"

run() {
    # Applicable only if dpkg exists
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian/Ubuntu system (dpkg missing)"
        return 0
    fi

    # Check if linux-base package exists (rule applicability logic)
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package not installed (rule not applicable)"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # Check service existence
    if ! $SYSTEMCTL -q list-unit-files isc-dhcp-server6.service 2>/dev/null; then
        echo "OK|$RULE_ID|Service isc-dhcp-server6.service not present"
        return 0
    fi

    # Check if disabled
    if $SYSTEMCTL is-enabled isc-dhcp-server6.service 2>/dev/null | grep -vq disabled; then
        echo "FAIL|$RULE_ID|Service isc-dhcp-server6.service is not disabled"
        return 0
    fi

    # Check if masked
    if ! $SYSTEMCTL is-enabled isc-dhcp-server6.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|Service isc-dhcp-server6.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|isc-dhcp-server6.service is disabled and masked"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
