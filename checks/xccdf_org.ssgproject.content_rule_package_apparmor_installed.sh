#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_apparmor_installed"

run() {

    # Not applicable inside a container
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Running inside a container"
        return 0
    fi

    # Check if apparmor package is installed
    if dpkg-query --show --showformat='${db:Status-Status}' apparmor 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|apparmor package is installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|apparmor package is not installed"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi