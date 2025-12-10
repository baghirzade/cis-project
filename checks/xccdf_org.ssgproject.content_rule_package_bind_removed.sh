#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_bind_removed"
TITLE="Ensure bind9 package is removed"

run() {
    # Only applicable to dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not present (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check package installation
    if ! dpkg -s bind9 >/dev/null 2>&1; then
        echo "OK|$RULE_ID|bind9 package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|bind9 package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
