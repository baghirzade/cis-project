#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_nftables_enabled"
TITLE="Ensure nftables service is enabled"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu and required packages)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi
    
    # 1. Check if 'nftables' package is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'nftables' package is not installed."
        return 0
    fi
    
    # 2. Check if 'firewalld' is running (nftables should be used only if firewalld is inactive)
    if systemctl is-active firewalld &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|'firewalld' service is running. Remediation assumes firewalld is not the intended service."
        return 0
    fi
    
    # Check if we are on a platform that uses linux-base (general Debian/Ubuntu check)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|'linux-base' package not installed."
        return 0
    fi

    # 3. Check if nftables service is enabled
    if systemctl is-enabled nftables.service &>/dev/null; then
        echo "OK|$RULE_ID|nftables service is enabled."
        return 0
    else
        # 4. If enabled fails, check if it's active (runtime status)
        if systemctl is-active nftables.service &>/dev/null; then
             echo "WARN|$RULE_ID|nftables service is active but not enabled (will not start on boot)."
             return 1
        else
             echo "WARN|$RULE_ID|nftables service is neither enabled nor active."
             return 1
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
