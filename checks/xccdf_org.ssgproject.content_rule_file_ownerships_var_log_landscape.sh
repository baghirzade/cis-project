#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_landscape"

run() {

    files=$(find -P /var/log/landscape/ -maxdepth 1 -type f \
        ! -user root ! -user landscape \
        -regextype posix-extended -regex '^.*$')

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|All /var/log/landscape files are owned by root or landscape"
        exit 0
    fi

    echo "WARN|$RULE_ID|Non-compliant ownership detected in /var/log/landscape:"
    echo "$files"
    exit 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
