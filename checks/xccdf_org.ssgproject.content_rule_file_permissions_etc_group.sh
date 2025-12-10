#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_group"
TITLE="Ensure permissions on /etc/group are configured"

run() {
    local TARGET_FILE="/etc/group"
    local MAX_PERMISSIONS="0644"
    local RETURN_CODE=0
    
    # 1. Check if the file exists
    if [ ! -f "$TARGET_FILE" ]; then
        echo "FAIL|$RULE_ID|Target file $TARGET_FILE does not exist."
        return 1
    fi
    
    # Get current permissions in octal format (including special bits)
    CURRENT_PERMS_OCTAL=$(stat -c "%a" "$TARGET_FILE")
    
    # a) Check for special permission bits (SUID/SGID/Sticky) (4000, 2000, 1000)
    local SPECIAL_BITS_SET=0
    # Check if the first digit (special bits) is non-zero
    if [ $(( (CURRENT_PERMS_OCTAL / 1000) * 1000 )) -ne 0 ]; then
        SPECIAL_BITS_SET=1
    fi

    # b) Check if Group or Other have Write (020 or 002)
    local BASE_PERMS=$(( CURRENT_PERMS_OCTAL % 1000 ))
    
    if [ "$SPECIAL_BITS_SET" -eq 1 ]; then
        echo "FAIL|$RULE_ID|Special permissions (SUID/SGID/Sticky) are set on $TARGET_FILE ($CURRENT_PERMS_OCTAL)."
        RETURN_CODE=1
    fi
    
    # Check if Group has Write (020) or Other has Write (002)
    # /etc/group should be writable only by root (0644 or less restricted only by owner)
    if [ $(( BASE_PERMS & 0022 )) -ne 0 ]; then
        echo "FAIL|$RULE_ID|Group or Other have write permissions set on $TARGET_FILE ($CURRENT_PERMS_OCTAL). Max allowed is $MAX_PERMISSIONS."
        RETURN_CODE=1
    fi

    if [ "$RETURN_CODE" -eq 0 ]; then
        echo "OK|$RULE_ID|Permissions on $TARGET_FILE are acceptable (Current: $CURRENT_PERMS_OCTAL, Max: $MAX_PERMISSIONS, no special bits)."
    fi

    return $RETURN_CODE
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
