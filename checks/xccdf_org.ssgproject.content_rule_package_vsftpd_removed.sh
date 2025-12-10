#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_vsftpd_removed"
TITLE="Ensure vsftpd package is removed"

run() {
    # Only applicable to Debian-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if vsftpd package is installed
    if ! dpkg -s vsftpd >/dev/null 2>&1; then
        echo "OK|$RULE_ID|vsftpd package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|vsftpd package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
