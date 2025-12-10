#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_sshd_config"
TITLE="Ensure SSHD configuration file owner is root"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    TARGET_FILE="/etc/ssh/sshd_config"
    EXPECTED_UID="0" # root user ID

    if [ ! -f "$TARGET_FILE" ]; then
        echo "FAIL|$RULE_ID|SSHD configuration file ($TARGET_FILE) not found."
        return 1
    fi

    # Get the current UID of the file owner
    CURRENT_UID=$(stat -c "%u" "$TARGET_FILE")
    CURRENT_OWNER_NAME=$(stat -c "%U" "$TARGET_FILE")

    if [ "$CURRENT_UID" = "$EXPECTED_UID" ]; then
        echo "OK|$RULE_ID|SSHD config file owner is correct ($CURRENT_OWNER_NAME, UID $CURRENT_UID)."
        return 0
    else
        echo "FAIL|$RULE_ID|SSHD config file owner is incorrect ($CURRENT_OWNER_NAME, UID $CURRENT_UID). Expected UID $EXPECTED_UID (root)."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
