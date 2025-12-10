#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_cron_weekly"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    TARGET_DIR="/etc/cron.weekly"

    # Check directory exists
    if [ ! -d "$TARGET_DIR" ]; then
        echo "WARN|$RULE_ID|Directory $TARGET_DIR does not exist"
        exit 1
    fi

    # Detect invalid permissions
    if find -H "$TARGET_DIR" -maxdepth 0 -perm /u+s,g+xwrs,o+xwrt | grep -q "$TARGET_DIR"; then
        CUR_PERMS=$(stat -c "%a" "$TARGET_DIR")
        echo "WARN|$RULE_ID|Invalid permissions on $TARGET_DIR (perm=$CUR_PERMS)"
        exit 1
    fi

    CUR_PERMS=$(stat -c "%a" "$TARGET_DIR")
    echo "OK|$RULE_ID|Permissions on $TARGET_DIR are secure (perm=$CUR_PERMS)"
    exit 0
}

run
