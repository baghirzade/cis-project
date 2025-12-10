#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_ftp_removed"
TITLE="Ensure ftp package is removed"

run() {
    # Only for dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if ftp package is installed
    if ! dpkg -s ftp >/dev/null 2>&1; then
        echo "OK|$RULE_ID|ftp package is not installed"
        return 0
    fi

    echo "WARN|$RULE_ID|ftp package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
