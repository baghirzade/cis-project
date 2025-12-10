#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_ufw_default_rule"

run() {

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # ufw must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw not installed"
        return 0
    fi

    # SCAP-selected firewall
    var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")
    if [[ "$var_network_filtering_service" != "ufw" ]]; then
        echo "NOTAPPL|$RULE_ID|Firewall selection is '$var_network_filtering_service'"
        return 0
    fi

    # Extract default rules
    incoming=$(ufw status verbose | grep -i "Default:" | grep -oP "incoming:\s*\K\S+")
    outgoing=$(ufw status verbose | grep -i "Default:" | grep -oP "outgoing:\s*\K\S+")
    routed=$(ufw status verbose | grep -i "Default:" | grep -oP "routed:\s*\K\S+")

    # Check required values
    if [[ "$incoming" == "deny" && "$outgoing" == "allow" && "$routed" == "deny" ]]; then
        echo "OK|$RULE_ID|UFW default rules are correctly configured"
    else
        echo "WARN|$RULE_ID|UFW defaults incorrect (incoming=$incoming outgoing=$outgoing routed=$routed)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
