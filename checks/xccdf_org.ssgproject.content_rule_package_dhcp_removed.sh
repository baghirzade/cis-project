#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_dhcp_removed"
TITLE="Ensure DHCP server package (isc-dhcp-server) is removed"

run() {
    # Only applicable on dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if isc-dhcp-server is installed
    if ! dpkg -s isc-dhcp-server >/dev/null 2>&1; then
        echo "OK|$RULE_ID|isc-dhcp-server package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|isc-dhcp-server package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
