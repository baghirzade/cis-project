#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_files_unowned_by_user"

run() {

    # Not applicable in containers
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    # Check for files owned by nonexistent users
    bad_files=$(find / -xdev -nouser 2>/dev/null)

    if [[ -z "$bad_files" ]]; then
        echo "OK|$RULE_ID|No unowned-by-user files detected"
    else
        echo "WARN|$RULE_ID|Files found with nonexistent user owners"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

