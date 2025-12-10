#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_gshadow"

run() {

    # Check file exists
    if [[ ! -e /etc/gshadow ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/gshadow does not exist"
        return 0
    fi

    perms=$(stat -c %a /etc/gshadow 2>/dev/null)

    if [[ "$perms" == "600" ]]; then
        echo "OK|$RULE_ID|Permissions are correct (600)"
    else
        echo "WARN|$RULE_ID|Permissions are $perms (expected: 600)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

