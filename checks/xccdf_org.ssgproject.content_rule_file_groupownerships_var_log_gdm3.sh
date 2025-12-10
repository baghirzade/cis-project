#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_gdm3"

run() {

    # Find files under /var/log/gdm3
    files=$(find -P /var/log/gdm3/ -type f -regextype posix-extended -regex '.*' 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No files found under /var/log/gdm3/"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        grp=$(stat -c %G "$f")

        # Compliant groups
        if [[ "$grp" == "gdm" || "$grp" == "gdm3" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group '$grp' is compliant"
        else
            echo "WARN|$RULE_ID|$f has invalid group '$grp' (expected: gdm, gdm3, or root)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

