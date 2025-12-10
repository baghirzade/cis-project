#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_openldap-servers_removed"
TITLE="Ensure slapd package is removed"

run() {
    # Applicable only to dpkg-based OS
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg unavailable (non-Debian/Ubuntu)"
        return 0
    fi

    # Check if slapd is installed
    if ! dpkg -s slapd >/dev/null 2>&1; then
        echo "OK|$RULE_ID|slapd package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|slapd package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
