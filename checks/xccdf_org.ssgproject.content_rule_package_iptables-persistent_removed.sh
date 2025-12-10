#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables-persistent_removed"
TITLE="Ensure package iptables-persistent is removed if ufw is installed"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # Control is only applicable if ufw is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|ufw is not installed, control not applicable."
        return 0
    fi

    # Check if iptables-persistent is present
    if dpkg-query --show --showformat='${db:Status-Status}' 'iptables-persistent' 2>/dev/null | grep -q '^installed$'; then
        echo "FAIL|$RULE_ID|ufw is installed, but iptables-persistent package is also installed (potential conflict)."
        return 1
    else
        echo "OK|$RULE_ID|ufw is installed, and iptables-persistent package is removed."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
