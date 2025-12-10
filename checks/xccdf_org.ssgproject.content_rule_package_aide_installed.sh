#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_aide_installed"
TITLE="AIDE package must be installed"

run() {
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    if dpkg -s aide >/dev/null 2>&1; then
        echo "OK|$RULE_ID|AIDE package is installed"
    else
        echo "WARN|$RULE_ID|AIDE package is missing (can be installed by remediation)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
