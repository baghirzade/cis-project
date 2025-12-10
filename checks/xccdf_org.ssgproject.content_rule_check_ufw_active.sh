#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_check_ufw_active"

run() {

    # linux-base must exist
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # ufw must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw package not installed"
        return 0
    fi

    # SCAP-selected firewall service
    var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")

    if [[ "$var_network_filtering_service" != "ufw" ]]; then
        echo "NOTAPPL|$RULE_ID|Selected firewall is '$var_network_filtering_service', not ufw"
        return 0
    fi

    # Check ufw active state
    if ufw status | grep -iq "Status: active"; then
        echo "OK|$RULE_ID|ufw is active"
    else
        echo "WARN|$RULE_ID|ufw is not active"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

