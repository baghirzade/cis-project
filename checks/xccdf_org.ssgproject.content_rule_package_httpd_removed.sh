#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_httpd_removed"
TITLE="Ensure apache2 package is removed"

run() {
    # Only for dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg missing (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check package install state
    if ! dpkg -s apache2 >/dev/null 2>&1; then
        echo "OK|$RULE_ID|apache2 package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|apache2 package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
