#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_dnsmasq_removed"
TITLE="Ensure dnsmasq package is removed"

run() {
    # Only applicable on dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if dnsmasq is installed
    if ! dpkg -s dnsmasq >/dev/null 2>&1; then
        echo "OK|$RULE_ID|dnsmasq package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|dnsmasq package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
