#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_nfs-kernel-server_removed"
TITLE="Ensure nfs-kernel-server package is removed"

run() {
    # Only applicable to Debian-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian system)"
        return 0
    fi

    # Check if nfs-kernel-server is installed
    if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
        echo "OK|$RULE_ID|nfs-kernel-server package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|nfs-kernel-server package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
