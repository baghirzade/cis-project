#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_cron_installed"

run() {

    # Check platform applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|linux-base not installed, rule not applicable"
        exit 0
    fi

    # Check cron installation
    if dpkg-query --show --showformat='${db:Status-Status}' cron 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|cron package installed"
        exit 0
    fi

    echo "FAIL|$RULE_ID|cron package is NOT installed"
    exit 1
}

run
