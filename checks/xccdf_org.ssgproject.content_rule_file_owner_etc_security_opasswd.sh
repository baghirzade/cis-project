#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_security_opasswd"
TITLE="Ensure /etc/security/opasswd has user ownership set to root (UID 0)"

run() {
    local TARGET_FILE="/etc/security/opasswd"
    local EXPECTED_UID="0"
    
    # 1. Check if the file exists
    if [ ! -f "$TARGET_FILE" ]; then
        # The file may not exist if password history is not configured or used.
        echo "OK|$RULE_ID|Target file $TARGET_FILE does not exist. Compliance assumed."
        return 0
    fi
    
    # 2. Get the current User ID (UID) of the file
    CURRENT_UID=$(stat -c "%u" "$TARGET_FILE")
    
    if [ "$CURRENT_UID" -eq "$EXPECTED_UID" ]; then
        echo "OK|$RULE_ID|User ownership of $TARGET_FILE is correctly set to UID $EXPECTED_UID."
        return 0
    else
        echo "FAIL|$RULE_ID|User ownership of $TARGET_FILE is $CURRENT_UID, expected $EXPECTED_UID."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
