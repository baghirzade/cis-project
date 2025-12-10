#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_tnftp_removed"
TITLE="Ensure tnftp package is removed"

run() {
    # Only for dpkg-based OS
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check tnftp installation
    if ! dpkg -s tnftp >/dev/null 2>&1; then
        echo "OK|$RULE_ID|tnftp package is not installed"
        return 0
    fi

    echo "WARN|$RULE_ID|tnftp package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
