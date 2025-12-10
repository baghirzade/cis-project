#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_wbtmp"

run() {

    files=$(find /var/log/ -maxdepth 1 -type f -regextype posix-extended \
        -regex '.*(b|w)tmp((\.|-)[^/]+)?$')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No wtmp/btmp log files found"
        exit 0
    fi

    noncompliant=0

    while IFS= read -r f; do
        owner=$(stat -c %U "$f")
        if [[ "$owner" != "root" ]]; then
            echo "WARN|$RULE_ID|$f owner '$owner' is NOT compliant (expected: root)"
            noncompliant=1
        fi
    done <<< "$files"

    if [[ $noncompliant -eq 0 ]]; then
        echo "OK|$RULE_ID|All wtmp/btmp files are owned by root"
        exit 0
    else
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
