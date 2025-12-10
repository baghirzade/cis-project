#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_ungroupowned"

run() {

    # Only applicable on bare metal / VM
    if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
        echo "NOTAPPL|$RULE_ID|Container environment detected"
        return 0
    fi

    # Find files with ungroupowned group
    bad_files=$(find / -xdev -nogroup 2>/dev/null)

    if [[ -z "$bad_files" ]]; then
        echo "OK|$RULE_ID|No ungroupowned files detected"
    else
        echo "WARN|$RULE_ID|Found files with nonexistent group ownership"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

