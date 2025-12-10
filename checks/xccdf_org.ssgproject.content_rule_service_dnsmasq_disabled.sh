#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_dnsmasq_disabled"
TITLE="Ensure dnsmasq service is disabled and masked"

run() {
    # dpkg must exist
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian/Ubuntu system (dpkg missing)"
        return 0
    fi

    # Rule applicable only if linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed, rule not applicable"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # If service does not exist → OK
    if ! $SYSTEMCTL -q list-unit-files dnsmasq.service 2>/dev/null; then
        echo "OK|$RULE_ID|dnsmasq.service not present"
        return 0
    fi

    # Must be disabled
    if $SYSTEMCTL is-enabled dnsmasq.service 2>/dev/null | grep -vq disabled; then
        echo "FAIL|$RULE_ID|dnsmasq.service is not disabled"
        return 0
    fi

    # Must be masked
    if ! $SYSTEMCTL is-enabled dnsmasq.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|dnsmasq.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|dnsmasq.service is disabled and masked"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
