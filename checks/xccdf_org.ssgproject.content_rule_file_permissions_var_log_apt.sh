#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_apt"

run() {

    bad_files=$(find -P /var/log/apt/ -maxdepth 1 \
        -perm /u+xs,g+xws,o+xwt \
        -type f -regextype posix-extended -regex '^.*$')

    if [[ -z "$bad_files" ]]; then
        echo "OK|$RULE_ID|All /var/log/apt files have correct permissions"
        exit 0
    fi

    echo "WARN|$RULE_ID|Files with incorrect permissions detected:"
    echo "$bad_files"
    exit 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
