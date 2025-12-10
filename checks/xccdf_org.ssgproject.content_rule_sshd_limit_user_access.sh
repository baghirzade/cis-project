#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_limit_user_access"
TITLE="Ensure SSHD limits user access"

run() {
    # Get the effective configuration for user/group access directives
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on access controls
    ALLOW_USERS=$(sshd -T 2>/dev/null | grep -i '^allowusers' | awk '{print $2}')
    ALLOW_GROUPS=$(sshd -T 2>/dev/null | grep -i '^allowgroups' | awk '{print $2}')
    DENY_USERS=$(sshd -T 2>/dev/null | grep -i '^denyusers' | awk '{print $2}')
    DENY_GROUPS=$(sshd -T 2>/dev/null | grep -i '^denygroups' | awk '{print $2}')
    
    # Check 1: Ensure positive access control (AllowUsers or AllowGroups) is used.
    # The strongest control is to explicitly allow only specified users/groups.
    if [ -z "$ALLOW_USERS" ] && [ -z "$ALLOW_GROUPS" ]; then
        echo "WARN|$RULE_ID|Neither AllowUsers nor AllowGroups is explicitly configured. All users may be allowed."
        return 1
    fi
    
    # Check 2 (Optional, but often implied): Ensure the list isn't empty if set.
    # If AllowUsers or AllowGroups is set, its value should not be empty.
    if ( [ -n "$ALLOW_USERS" ] && [ "$ALLOW_USERS" = "none" ] ) || \
       ( [ -n "$ALLOW_GROUPS" ] && [ "$ALLOW_GROUPS" = "none" ] ); then
        echo "WARN|$RULE_ID|AllowUsers/AllowGroups is set, but to an empty value (e.g., 'none')."
        return 1
    fi

    echo "OK|$RULE_ID|User access is limited via SSHD configuration (AllowUsers: $ALLOW_USERS, AllowGroups: $ALLOW_GROUPS)."
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
