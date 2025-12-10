#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_rsyslog_installed"
TITLE="Rsyslog package must be installed"

run() {
    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if rsyslog is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
        echo "WARN|$RULE_ID|rsyslog package is not installed"
        return 0
    fi

    echo "OK|$RULE_ID|rsyslog package is installed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
