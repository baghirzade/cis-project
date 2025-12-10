#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_sssd"

run() {

    files=$(find -P /var/log/sssd/ -type f -regextype posix-extended -regex '.*' 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No files found under /var/log/sssd/"
        exit 0
    fi

    noncompliant=0

    for f in $files; do
        grp=$(stat -c %G "$f")

        if [[ "$grp" == "sssd" || "$grp" == "root" ]]; then
            echo "OK|$RULE_ID|$f group '$grp' is compliant"
        else
            echo "WARN|$RULE_ID|$f has noncompliant group '$grp' (expected: sssd or root)"
            noncompliant=1
        fi
    done

    exit $noncompliant
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

