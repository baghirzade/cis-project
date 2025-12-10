#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_gshadow"

run() {

    # Ensure shadow group exists
    if ! getent group shadow >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|shadow group not present"
        return 0
    fi

    # Check file existence
    if [[ ! -e /etc/gshadow ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/gshadow does not exist"
        return 0
    fi

    # Check group ownership
    grp=$(stat -c %G /etc/gshadow 2>/dev/null)

    if [[ "$grp" == "shadow" ]]; then
        echo "OK|$RULE_ID|/etc/gshadow group owner is correctly set to shadow"
    else
        echo "WARN|$RULE_ID|/etc/gshadow group owner is '$grp' (expected: shadow)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

