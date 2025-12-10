#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_nginx_removed"
TITLE="Ensure nginx package is removed"

run() {
    # dpkg required → Debian/Ubuntu only
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check nginx installation
    if ! dpkg -s nginx >/dev/null 2>&1; then
        echo "OK|$RULE_ID|nginx package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|nginx package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
