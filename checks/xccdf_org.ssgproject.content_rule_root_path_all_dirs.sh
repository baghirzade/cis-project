#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_root_path_all_dirs"

run() {
    PATH_TO_CHECK="${PATH}"
    IFS=':' read -ra PATH_DIRS <<< "$PATH_TO_CHECK"

    noncompliant=0

    for dir in "${PATH_DIRS[@]}"; do
        
        # Empty PATH entry → represents current working dir → always non-compliant
        if [ -z "$dir" ]; then
            echo "WARN|$RULE_ID|Empty PATH entry (':') detected"
            noncompliant=1
            continue
        fi

        if [ ! -e "$dir" ]; then
            echo "WARN|$RULE_ID|PATH entry '$dir' does not exist"
            noncompliant=1
            continue
        fi

        if [ ! -d "$dir" ]; then
            echo "WARN|$RULE_ID|PATH entry '$dir' is not a directory"
            noncompliant=1
            continue
        fi
    done

    if [ "$noncompliant" -eq 0 ]; then
        echo "OK|$RULE_ID|All PATH entries exist and are directories"
        return 0
    else
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi