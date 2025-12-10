#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_max_auth_tries"
TITLE="Ensure SSHD MaxAuthTries is set to 4 or less"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required maximum MaxAuthTries value
    REQUIRED_MAX_VALUE='4'
    
    # Get the effective MaxAuthTries configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on MaxAuthTries
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^maxauthtries' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default value is often 6 in recent OpenSSH versions. If not found, it is non-compliant as it is not explicitly set.
        echo "WARN|$RULE_ID|MaxAuthTries setting not found in active sshd configuration."
        return 1
    fi
    
    # Ensure the current value is an integer and is less than or equal to the required max value.
    if [[ "$CURRENT_VALUE" =~ ^[0-9]+$ ]] && [ "$CURRENT_VALUE" -le "$REQUIRED_MAX_VALUE" ]; then
        echo "OK|$RULE_ID|MaxAuthTries is set to $CURRENT_VALUE, which is acceptable (<= $REQUIRED_MAX_VALUE)."
        return 0
    else
        echo "WARN|$RULE_ID|MaxAuthTries is set to $CURRENT_VALUE, expected value is $REQUIRED_MAX_VALUE or less."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
