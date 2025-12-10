#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_waagent"
PATTERN_REGEX='.*waagent\.log([^/]+)?$'

run() {

    files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex "$PATTERN_REGEX")

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|No matching waagent.log files found"
        exit 0
    fi

    for f in $files; do
        
        perms=$(stat -c "%A" "$f")

        # Forbidden bits: suid/sgid/sticky
        if echo "$perms" | grep -qE 's|t'; then
            echo "WARN|$RULE_ID|Forbidden special bits on $f"
            exit 1
        fi

        # Group write or execute forbidden
        if echo "$perms" | grep -qE '^......[wx]'; then
            echo "WARN|$RULE_ID|Invalid group permissions on $f"
            exit 1
        fi

        # Other (world) any permission forbidden
        if echo "$perms" | grep -qE '^.......[rwx]'; then
            echo "WARN|$RULE_ID|Invalid other permissions on $f"
            exit 1
        fi
    done

    echo "OK|$RULE_ID|All waagent.log files have correct permissions"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
