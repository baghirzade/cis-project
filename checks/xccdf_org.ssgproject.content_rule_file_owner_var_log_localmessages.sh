#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_localmessages"

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*localmessages.*')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No localmessages files found"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        owner=$(stat -c %U "$f")

        if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
            echo "OK|$RULE_ID|$f owner '$owner' is compliant"
        else
            echo "WARN|$RULE_ID|$f has owner '$owner' (expected: syslog or root)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

