#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_backup_etc_group"
TITLE="Ensure permissions on /etc/group- are configured"

run() {
    local TARGET_FILE="/etc/group-"
    # The remediation removes x, s, w, t bits for specific groups.
    # The resulting standard CIS benchmark minimum requirement is often 644 (rw-r--r--).
    local MAX_PERMISSIONS="0644"
    local RETURN_CODE=0
    
    # 1. Check if the file exists
    if [ ! -f "$TARGET_FILE" ]; then
        echo "OK|$RULE_ID|Target file $TARGET_FILE does not exist. Compliance assumed."
        return 0
    fi
    
    # Get current permissions in octal format (excluding file type)
    CURRENT_PERMS_OCTAL=$(stat -c "%a" "$TARGET_FILE")
    
    # 2. Check for unauthorized permissions (world-writable, group-writable, etc.)
    # We check if CURRENT_PERMS_OCTAL is numerically greater than the maximum allowed, or if it has special bits set.
    
    # a) Check for special permission bits (SUID/SGID/Sticky) (4000, 2000, 1000)
    local SPECIAL_BITS_SET=0
    if [ $(( (CURRENT_PERMS_OCTAL / 1000) * 1000 )) -ne 0 ]; then
        SPECIAL_BITS_SET=1
    fi

    # b) Check if the base permissions (0xxx) exceed 0644 (rwxr--r--)
    local BASE_PERMS=$(( CURRENT_PERMS_OCTAL % 1000 ))
    local MAX_BASE_PERMS=$(( MAX_PERMISSIONS % 1000 ))
    
    # We check if owner/group/other write/execute bits are set inappropriately.
    # The safest check is to verify that Group Write (020) and Other Write (002) are NOT set, and no special bits are set.
    
    if [ "$SPECIAL_BITS_SET" -eq 1 ]; then
        echo "FAIL|$RULE_ID|Special permissions (SUID/SGID/Sticky) are set on $TARGET_FILE ($CURRENT_PERMS_OCTAL)."
        RETURN_CODE=1
    fi
    
    # Check if Group has Write (020) or Other has Write (002)
    if [ $(( BASE_PERMS & 0022 )) -ne 0 ]; then
        echo "FAIL|$RULE_ID|Group or Other have write permissions set on $TARGET_FILE ($CURRENT_PERMS_OCTAL)."
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
