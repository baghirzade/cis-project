#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_sudo_installed"
TITLE="sudo package must be installed"

run() {
    # Only Debian/Ubuntu systems have dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicability: only when linux-base is installed (same as SCAP)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (rule not applicable)"
        return 0
    fi

    # Check if sudo package is installed
    if dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|sudo package is installed"
    else
        echo "WARN|$RULE_ID|sudo package is not installed"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
