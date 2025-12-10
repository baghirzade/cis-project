#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_ufw_enabled"

run() {

    # linux-base yoxdursa — applicable deyil
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # UFW paketi quraşdırılmayıbsa
    if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw package not installed"
        return 0
    fi

    # Firewall selection (SCAP logic)
    var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")

    if [[ "$var_network_filtering_service" != "ufw" ]]; then
        echo "NOTAPPL|$RULE_ID|Selected firewall is '$var_network_filtering_service', not ufw"
        return 0
    fi

    # Check ufw service state
    if systemctl is-enabled ufw &>/dev/null && systemctl is-active ufw &>/dev/null; then
        echo "OK|$RULE_ID|ufw service is enabled and active"
    else
        echo "WARN|$RULE_ID|ufw service is not enabled/active"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

