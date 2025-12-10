#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_max_sessions"
TITLE="Ensure SSHD MaxSessions is set correctly (e.g., 10)"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required MaxSessions value (the standard CIS benchmark value)
    REQUIRED_VALUE='10'
    
    # Get the effective MaxSessions configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on MaxSessions
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^maxsessions' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default value is 10 in recent OpenSSH versions, but for compliance we ensure it's explicitly set.
        echo "FAIL|$RULE_ID|MaxSessions setting not found in active sshd configuration."
        return 1
    fi
    
    # Check if the current value is equal to the required value (or less, but CIS often mandates the specific value)
    # Since the remediation sets it to '10', we check for exact match.
    if [ "$CURRENT_VALUE" -le "$REQUIRED_VALUE" ]; then
        echo "OK|$RULE_ID|MaxSessions is set to $CURRENT_VALUE, which is acceptable (<= $REQUIRED_VALUE)."
        return 0
    else
        echo "FAIL|$RULE_ID|MaxSessions is set to $CURRENT_VALUE, expected value is $REQUIRED_VALUE or less."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
