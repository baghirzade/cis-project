#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_wbtmp"

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f \
        -regextype posix-extended -regex '.*(b|w)tmp((\.|-)[^\/]+)?' 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No wtmp/btmp files found"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        grp=$(stat -c %G "$f")

        if [[ "$grp" == "utmp" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group '$grp' is compliant"
        else
            echo "WARN|$RULE_ID|$f has non-compliant group '$grp' (expected: utmp or root)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

