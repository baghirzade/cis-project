#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_ip6tables_rules_for_open_ports"
TITLE="Ensure ip6tables has rules for all open IPv6 ports"

run() {
    # ip6tables required
    if ! command -v ip6tables >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|ip6tables not available"
        return 0
    fi

    # nftables disables this rule
    if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables installed (rule not applicable)"
        return 0
    fi

    # ufw disables this rule
    if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw installed (rule not applicable)"
        return 0
    fi

    # Collect listening IPv6 ports
    mapfile -t PORTS < <(ss -tlunp 'ip6' 2>/dev/null | awk 'NR>1 {print $5}' | sed 's/.*://')

    if [ ${#PORTS[@]} -eq 0 ]; then
        echo "OK|$RULE_ID|No open IPv6 TCP ports detected"
        return 0
    fi

    MISSING=0

    for PORT in "${PORTS[@]}"; do
        if ! ip6tables -S INPUT | grep -qE "^-A INPUT .* --dport ${PORT} .* -j ACCEPT"; then
            echo "WARN|$RULE_ID|Missing IPv6 firewall allow rule for TCP port ${PORT}"
            MISSING=1
        fi
    done

    if [ $MISSING -eq 0 ]; then
        echo "OK|$RULE_ID|All open IPv6 ports have matching ip6tables allow rules"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
