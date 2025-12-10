#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_security_opasswd_old"
TITLE="Ensure /etc/security/opasswd.old has group ownership set to root (GID 0)"

run() {
    local TARGET_FILE="/etc/security/opasswd.old"
    local EXPECTED_GID="0"
    
    # 1. Check if the file exists
    if [ ! -f "$TARGET_FILE" ]; then
        # The file may not exist if password history is not configured or used.
        echo "OK|$RULE_ID|Target file $TARGET_FILE does not exist. Compliance assumed."
        return 0
    fi
    
    # 2. Get the current Group ID (GID) of the file
    CURRENT_GID=$(stat -c "%g" "$TARGET_FILE")
    
    if [ "$CURRENT_GID" -eq "$EXPECTED_GID" ]; then
        echo "OK|$RULE_ID|Group ownership of $TARGET_FILE is correctly set to GID $EXPECTED_GID."
        return 0
    else
        echo "FAIL|$RULE_ID|Group ownership of $TARGET_FILE is $CURRENT_GID, expected $EXPECTED_GID."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
