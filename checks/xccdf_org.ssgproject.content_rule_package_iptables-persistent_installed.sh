#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables-persistent_installed"
TITLE="Ensure package iptables-persistent is installed (if iptables is used)"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu and if iptables is installed)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # Check if iptables is installed. The control is only applicable if iptables is the filtering mechanism.
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|iptables is not installed, control not applicable."
        return 0
    fi

    # Check if iptables-persistent is installed
    if dpkg-query --show --showformat='${db:Status-Status}' 'iptables-persistent' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Package iptables-persistent is installed."
        return 0
    else
        echo "WARN|$RULE_ID|Package iptables-persistent is not installed. iptables rules may not persist across reboots."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
