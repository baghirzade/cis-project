#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_loopback_traffic"
TITLE="Ensure correct IPv4 loopback traffic rules exist"

run() {
    # dpkg required (Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available on this system"
        return 0
    fi

    # Rule applies only if iptables is installed AND nftables/ufw are NOT installed
    if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables installed (rule not applicable)"
        return 0
    fi

    if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw installed (rule not applicable)"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|iptables not installed"
        return 0
    fi

    # Check iptables rules
    INPUT_RULE=$(iptables -S INPUT | grep -E "^-A INPUT -i lo -j ACCEPT")
    OUTPUT_RULE=$(iptables -S OUTPUT | grep -E "^-A OUTPUT -o lo -j ACCEPT")
    DROP_RULE=$(iptables -S INPUT | grep -E "^-A INPUT -s 127\.0\.0\.0/8 -j DROP")

    if [ -z "$INPUT_RULE" ] || [ -z "$OUTPUT_RULE" ] || [ -z "$DROP_RULE" ]; then
        echo "WARN|$RULE_ID|IPv4 loopback rules missing or incorrect"
        return 0
    fi

    echo "OK|$RULE_ID|IPv4 loopback traffic rules are correctly configured"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
