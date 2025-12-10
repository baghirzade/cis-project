#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_nftables_installed"
TITLE="Ensure nftables is installed when no other firewall is active"

run() {

    # System must be Debian-based
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    IPT_ACTIVE=0
    UFW_ACTIVE=0

    systemctl is-active iptables &>/dev/null && IPT_ACTIVE=1
    systemctl is-active ufw &>/dev/null && UFW_ACTIVE=1

    # nftables is required only if *both* other firewall services are inactive
    if [[ $IPT_ACTIVE -eq 0 && $UFW_ACTIVE -eq 0 ]]; then
        if dpkg-query --show --showformat='${db:Status-Status}' nftables \
            2>/dev/null | grep -q '^installed$'; then
            echo "OK|$RULE_ID|nftables installed as required"
        else
            echo "WARN|$RULE_ID|nftables is NOT installed while no other firewall is active"
        fi
    else
        echo "NOTAPPL|$RULE_ID|Another firewall (iptables or ufw) is active"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
