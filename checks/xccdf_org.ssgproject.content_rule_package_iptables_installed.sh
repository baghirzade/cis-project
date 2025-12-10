#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables_installed"
TITLE="Ensure package iptables is installed (if it is the chosen firewall service)"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Remediation applicability condition check
    local is_applicable=true
    if systemctl is-active nftables &>/dev/null; then
        is_applicable=false
    fi
    if systemctl is-active ufw &>/dev/null; then
        is_applicable=false
    fi
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        is_applicable=false
    fi

    if ! $is_applicable; then
        echo "NOTAPPL|$RULE_ID|Control is not applicable (nftables or ufw is active, or 'linux-base' is missing)."
        return 0
    fi
    
    # Check if iptables is installed
    if dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Package iptables is installed."
        return 0
    else
        echo "FAIL|$RULE_ID|Package iptables is not installed, and no other primary firewall is active."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
