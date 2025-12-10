#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_iptables_rules_for_open_ports"
TITLE="Ensure iptables has rules for all open IPv4 TCP ports"

run() {
    # iptables required
    if ! command -v iptables >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|iptables command not available"
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

    # Detect open IPv4 TCP ports
    mapfile -t PORTS < <(ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | sed 's/.*://')

    if [ ${#PORTS[@]} -eq 0 ]; then
        echo "OK|$RULE_ID|No open IPv4 TCP ports detected"
        return 0
    fi

    MISSING=0

    # Check rules for each port
    for PORT in "${PORTS[@]}"; do
        if ! iptables -S INPUT | grep -qE "^-A INPUT .* --dport ${PORT} .* -j ACCEPT"; then
            echo "WARN|$RULE_ID|Missing IPv4 firewall allow rule for TCP port ${PORT}"
            MISSING=1
        fi
    done

    if [ $MISSING -eq 0 ]; then
        echo "OK|$RULE_ID|All open IPv4 TCP ports have matching iptables allow rules"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
