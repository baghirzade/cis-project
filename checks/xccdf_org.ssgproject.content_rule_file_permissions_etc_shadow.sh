#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_shadow"

run() {

    # File must exist
    if [[ ! -e /etc/shadow ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/shadow does not exist"
        return 0
    fi

    perms=$(stat -c %a /etc/shadow 2>/dev/null)

    if [[ "$perms" == "600" ]]; then
        echo "OK|$RULE_ID|Permissions are correct (600)"
    else
        echo "WARN|$RULE_ID|Permissions are $perms (expected: 600)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

