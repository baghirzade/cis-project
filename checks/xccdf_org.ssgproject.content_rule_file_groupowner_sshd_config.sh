#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_sshd_config"
TITLE="Ensure SSHD configuration file group owner is root (GID 0)"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    TARGET_FILE="/etc/ssh/sshd_config"
    EXPECTED_GID="0" # root group ID

    if [ ! -f "$TARGET_FILE" ]; then
        echo "FAIL|$RULE_ID|SSHD configuration file ($TARGET_FILE) not found."
        return 1
    fi

    # Get the current GID of the file group owner
    CURRENT_GID=$(stat -c "%g" "$TARGET_FILE")
    CURRENT_GROUP_NAME=$(stat -c "%G" "$TARGET_FILE")

    if [ "$CURRENT_GID" = "$EXPECTED_GID" ]; then
        echo "OK|$RULE_ID|SSHD config file group owner is correct ($CURRENT_GROUP_NAME, GID $CURRENT_GID)."
        return 0
    else
        echo "FAIL|$RULE_ID|SSHD config file group owner is incorrect ($CURRENT_GROUP_NAME, GID $CURRENT_GID). Expected GID $EXPECTED_GID (root)."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
