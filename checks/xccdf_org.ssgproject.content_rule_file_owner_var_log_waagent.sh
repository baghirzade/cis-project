#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_waagent"

run() {

    files=$(find /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*waagent\.log.*')

    if [[ -z "$files" ]]; then
        echo "NOTAPPL|$RULE_ID|No waagent log files found"
        exit 0
    fi

    noncompliant=0

    while IFS= read -r f; do
        owner=$(stat -c %U "$f")
        if [[ "$owner" != "syslog" && "$owner" != "root" ]]; then
            echo "WARN|$RULE_ID|$f owner '$owner' is NOT compliant (expected syslog or root)"
            noncompliant=1
        fi
    done <<< "$files"

    if [[ $noncompliant -eq 0 ]]; then
        echo "OK|$RULE_ID|All waagent logs have correct owner (syslog/root)"
        exit 0
    else
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

