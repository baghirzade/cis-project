#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_ufw_rules_for_open_ports"

run() {

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # UFW required
    if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw not installed"
        return 0
    fi

    # SCAP-selected firewall must be ufw
    var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")
    if [[ "$var_network_filtering_service" != "ufw" ]]; then
        echo "NOTAPPL|$RULE_ID|Firewall '$var_network_filtering_service' selected"
        return 0
    fi

    # Get open TCP ports
    open_ports=$(ss -tln | awk 'NR>1 {print $4}' | sed 's/.*://')

    missing_rules=0

    for port in $open_ports; do
        if [[ -z "$port" ]]; then continue; fi
        
        ufw status numbered | grep -q "ALLOW IN .* $port" || missing_rules=1
    done

    if [[ $missing_rules -eq 0 ]]; then
        echo "OK|$RULE_ID|All open ports have UFW allow rules"
    else
        echo "WARN|$RULE_ID|Some open ports do not have UFW allow rules"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
