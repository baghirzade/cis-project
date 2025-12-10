#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_shadow"

run() {

    # shadow group must exist
    if ! getent group shadow >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|shadow group not present"
        return 0
    fi

    # check existence of file
    if [[ ! -e /etc/shadow ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/shadow does not exist"
        return 0
    fi

    grp=$(stat -c %G /etc/shadow 2>/dev/null)

    if [[ "$grp" == "shadow" ]]; then
        echo "OK|$RULE_ID|/etc/shadow group owner is shadow"
    else
        echo "WARN|$RULE_ID|group owner is '$grp' (expected: shadow)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

