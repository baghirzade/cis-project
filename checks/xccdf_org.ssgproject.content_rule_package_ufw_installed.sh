#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_ufw_installed"

run() {

    # linux-base paketi olmalıdır
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # UFW quraşdırılıb?
    if dpkg-query --show --showformat='${db:Status-Status}' ufw \
        2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|ufw package is installed"
    else
        echo "WARN|$RULE_ID|ufw package is missing"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

