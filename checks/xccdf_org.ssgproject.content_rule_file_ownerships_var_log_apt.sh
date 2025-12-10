#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_apt"

run() {

    files=$(find -P /var/log/apt/ -maxdepth 1 -type f \
        ! -user 0 \
        -regextype posix-extended -regex '^.*$')

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|All /var/log/apt files have compliant ownership (root)"
        exit 0
    fi

    echo "WARN|$RULE_ID|Non-compliant ownership detected in /var/log/apt:"
    echo "$files"
    exit 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
