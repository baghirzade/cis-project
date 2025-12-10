#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_autofs_removed"

run() {

    if dpkg -l | grep -q "^ii\s\+autofs"; then
        echo "WARN|$RULE_ID|Package autofs is installed"
        exit 1
    else
        echo "OK|$RULE_ID|Package autofs is not installed"
        exit 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
