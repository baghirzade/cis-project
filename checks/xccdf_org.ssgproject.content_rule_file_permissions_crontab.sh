#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_crontab"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    TARGET="/etc/crontab"

    # Check file exists
    if [ ! -f "$TARGET" ]; then
        echo "FAIL|$RULE_ID|File $TARGET does not exist"
        exit 1
    fi

    # Detect invalid permissions
    if stat -c "%A" "$TARGET" | grep -qE 's|g.w|o.w|o.rwx'; then
        CUR_PERMS=$(stat -c "%a" "$TARGET")
        echo "FAIL|$RULE_ID|Invalid permissions on $TARGET (perm=$CUR_PERMS)"
        exit 1
    fi

    CUR_PERMS=$(stat -c "%a" "$TARGET")
    echo "OK|$RULE_ID|Permissions on $TARGET are secure (perm=$CUR_PERMS)"
    exit 0
}

run
