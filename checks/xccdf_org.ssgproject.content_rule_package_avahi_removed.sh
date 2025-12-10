#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_avahi_removed"

run() {

    if dpkg-query --show --showformat='${db:Status-Status}' avahi-daemon 2>/dev/null | grep -q '^installed$'; then
        echo "FAIL|$RULE_ID|avahi-daemon package is installed"
        exit 1
    fi

    echo "OK|$RULE_ID|avahi-daemon package is removed"
    exit 0
}

run
