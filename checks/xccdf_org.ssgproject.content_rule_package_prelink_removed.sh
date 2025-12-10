#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_prelink_removed"
TITLE="Package 'prelink' must be removed"

run() {
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    if dpkg -s prelink >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|Package 'prelink' is installed (can be removed by remediation)"
    else
        echo "OK|$RULE_ID|Package 'prelink' is not installed"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
