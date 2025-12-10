#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_shells"

run() {

    # Ensure root user exists
    if ! id root >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|root user not present"
        return 0
    fi

    # Check file exists
    if [[ ! -e /etc/shells ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/shells does not exist"
        return 0
    fi

    owner=$(stat -c %U /etc/shells 2>/dev/null)

    if [[ "$owner" == "root" ]]; then
        echo "OK|$RULE_ID|/etc/shells owner is root"
    else
        echo "WARN|$RULE_ID|owner is '$owner' (expected: root)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

