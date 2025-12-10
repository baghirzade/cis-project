#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_syslog"
TARGET_FILE="/var/log/syslog"

run() {

    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "OK|$RULE_ID|Target file not found: $TARGET_FILE"
        exit 0
    fi

    # Allowed perms: no suid, no sgid, no sticky, no write for group/other
    # Check forbidden permission bits explicitly
    if stat -c "%A" "$TARGET_FILE" | grep -qE 's|t'; then
        echo "WARN|$RULE_ID|Forbidden special bits (suid|sgid|sticky) detected on $TARGET_FILE"
        exit 1
    fi

    # Check group write or execute
    if stat -c "%A" "$TARGET_FILE" | grep -qE '^......[wx]'; then
        echo "WARN|$RULE_ID|Group has invalid permissions on $TARGET_FILE"
        exit 1
    fi

    # Check other read/write/execute
    if stat -c "%A" "$TARGET_FILE" | grep -qE '^.......[rwx]'; then
        echo "WARN|$RULE_ID|Other has invalid permissions on $TARGET_FILE"
        exit 1
    fi

    echo "OK|$RULE_ID|File permissions for $TARGET_FILE are correct"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
