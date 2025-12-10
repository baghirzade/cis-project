#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_landscape"

run() {

    files=$(find -P /var/log/landscape/ -maxdepth 1 -type f -regextype posix-extended -regex '^.*$' 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No files found under /var/log/landscape/"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        grp=$(stat -c %G "$f")

        if [[ "$grp" == "root" || "$grp" == "landscape" ]]; then
            echo "OK|$RULE_ID|$f group '$grp' is compliant"
        else
            echo "WARN|$RULE_ID|$f has invalid group '$grp' (expected: root or landscape)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

