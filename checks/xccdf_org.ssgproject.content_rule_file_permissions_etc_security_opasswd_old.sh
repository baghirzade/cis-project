#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_security_opasswd_old"
TITLE="Ensure permissions on /etc/security/opasswd.old are configured"

run() {
    local TARGET_FILE="/etc/security/opasswd.old"
    # Expected maximum permission for security files is often 600 (rw-------)
    local MAX_PERMISSIONS="0600"
    local RETURN_CODE=0
    
    # 1. Check if the file exists
    if [ ! -f "$TARGET_FILE" ]; then
        echo "OK|$RULE_ID|Target file $TARGET_FILE does not exist. Compliance assumed."
        return 0
    fi
    
    # Get current permissions in octal format (including special bits)
    CURRENT_PERMS_OCTAL=$(stat -c "%a" "$TARGET_FILE")
    
    # a) Check for special permission bits (SUID/SGID/Sticky) (4000, 2000, 1000)
    local SPECIAL_BITS_SET=0
    if [ $(( (CURRENT_PERMS_OCTAL / 1000) * 1000 )) -ne 0 ]; then
        SPECIAL_BITS_SET=1
    fi
    
    # b) Check if the base permissions (0xxx) are too permissive.
    # We require permissions to be 600 or less restrictive only by owner.
    # Checking for Group/Other permissions (077): if any of these bits are set, it fails.
    local GROUP_OTHER_PERMS=$(( CURRENT_PERMS_OCTAL & 0077 ))
    
    if [ "$SPECIAL_BITS_SET" -eq 1 ]; then
        echo "FAIL|$RULE_ID|Special permissions (SUID/SGID/Sticky) are set on $TARGET_FILE ($CURRENT_PERMS_OCTAL)."
        RETURN_CODE=1
    fi
    
    # Check if any Group or Other bits are set
    if [ "$GROUP_OTHER_PERMS" -ne 0 ]; then
        echo "FAIL|$RULE_ID|Group or Other permissions are set on $TARGET_FILE ($CURRENT_PERMS_OCTAL). Max allowed is $MAX_PERMISSIONS."
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
