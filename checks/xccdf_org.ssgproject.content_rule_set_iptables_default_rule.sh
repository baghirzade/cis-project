#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_iptables_default_rule"
TITLE="Ensure iptables default policies are set to DROP"

run() {
    # iptables must exist
    if ! command -v iptables >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|iptables not available"
        return 0
    fi

    # nftables or ufw override iptables rule logic
    if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables installed (rule not applicable)"
        return 0
    fi

    if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw installed (rule not applicable)"
        return 0
    fi

    # Read default policies
    INPUT_POLICY=$(iptables -S INPUT 2>/dev/null | awk '/^-P INPUT/ {print $3}')
    OUTPUT_POLICY=$(iptables -S OUTPUT 2>/dev/null | awk '/^-P OUTPUT/ {print $3}')
    FORWARD_POLICY=$(iptables -S FORWARD 2>/dev/null | awk '/^-P FORWARD/ {print $3}')

    BAD=0

    [[ "$INPUT_POLICY" != "DROP" ]] && BAD=1
    [[ "$OUTPUT_POLICY" != "DROP" ]] && BAD=1
    [[ "$FORWARD_POLICY" != "DROP" ]] && BAD=1

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|One or more iptables default policies are NOT DROP"
        return 0
    fi

    echo "OK|$RULE_ID|iptables default INPUT/OUTPUT/FORWARD policies are all DROP"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
