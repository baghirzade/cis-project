#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_journal"

run() {

    files=$(find /var/log/ -type f -regextype posix-extended -regex '.*\.journal[~]?')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No .journal or .journal~ files found"
        return 0
    fi

    bad_found=0

    while IFS= read -r f; do
        grp=$(stat -c %G "$f")
        if [[ "$grp" == "systemd-journal" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group is '$grp'"
        else
            echo "WARN|$RULE_ID|$f group is '$grp' (expected: systemd-journal or root)"
            bad_found=1
        fi
    done <<< "$files"

    return $bad_found
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

