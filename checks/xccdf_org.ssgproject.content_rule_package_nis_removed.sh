#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_nis_removed"
TITLE="Ensure NIS package is removed"

run() {
    # Rule only applies on Debian/Ubuntu (dpkg-based)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if package exists in repo or system
    if ! dpkg -s nis >/dev/null 2>&1; then
        echo "OK|$RULE_ID|nis package is not installed"
        return 0
    fi

    # Package installed → should be removed
    echo "FAIL|$RULE_ID|nis package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
