#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_lastlog"

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*lastlog(\.[^/]+)?')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No lastlog files found"
        return 0
    fi

    bad_found=0

    while IFS= read -r f; do
        grp=$(stat -c %G "$f")
        if [[ "$grp" == "utmp" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group is '$grp'"
        else
            echo "WARN|$RULE_ID|$f group is '$grp' (expected: utmp or root)"
            bad_found=1
        fi
    done <<< "$files"

    return $bad_found
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

