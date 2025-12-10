#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_lastlog"

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*lastlog(\.[^/]+)?$')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No lastlog files found"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        owner=$(stat -c %u "$f")

        if [[ "$owner" -eq 0 ]]; then
            echo "OK|$RULE_ID|$f owner '$owner' is compliant"
        else
            echo "WARN|$RULE_ID|$f has owner '$owner' (expected: 0)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

