#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_dovecot_removed"
TITLE="Ensure dovecot-core package is removed"

run() {
    # Only for dpkg-based OS (Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu)"
        return 0
    fi

    # Check if dovecot-core is installed
    if ! dpkg -s dovecot-core >/dev/null 2>&1; then
        echo "OK|$RULE_ID|dovecot-core package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|dovecot-core package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
