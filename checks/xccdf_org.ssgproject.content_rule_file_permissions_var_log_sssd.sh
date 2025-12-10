#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_sssd"
TARGET_DIR="/var/log/sssd"

run() {

    if [[ ! -d "$TARGET_DIR" ]]; then
        echo "OK|$RULE_ID|Directory not found: $TARGET_DIR"
        exit 0
    fi

    # Find files with forbidden permissions:
    #   user:  SUID
    #   group: SUID or SGID
    #   other: read, write, execute, sticky
    bad_files=$(find -P "$TARGET_DIR" -type f -perm /u+xs,g+xs,o+rwxst 2>/dev/null)

    if [[ -n "$bad_files" ]]; then
        echo "WARN|$RULE_ID|Files with invalid permissions detected:"
        echo "$bad_files"
        exit 1
    fi

    echo "OK|$RULE_ID|All files in $TARGET_DIR have correct permissions"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
