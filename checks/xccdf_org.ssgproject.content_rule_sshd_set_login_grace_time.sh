#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_login_grace_time"
TITLE="Ensure SSHD LoginGraceTime is set to 60 seconds or less"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required maximum LoginGraceTime value in seconds
    REQUIRED_MAX_VALUE='60'
    
    # Get the effective LoginGraceTime configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on LoginGraceTime
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^logingracetime' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default value is often 120s. If not found, it is non-compliant as it is not explicitly set or too long.
        echo "WARN|$RULE_ID|LoginGraceTime setting not found in active sshd configuration."
        return 1
    fi
    
    # Convert '0' to the effective value (usually 0 is used to disable, but here we assume seconds).
    # OpenSSH uses time units (like 1m, 1h), but the CIS remediation sets a numeric value (seconds).
    # We trust sshd -T returns seconds or a convertible value. For a simple check, we use direct integer comparison.

    # Ensure the current value is an integer and is less than or equal to the required max value.
    if [[ "$CURRENT_VALUE" =~ ^[0-9]+$ ]] && [ "$CURRENT_VALUE" -le "$REQUIRED_MAX_VALUE" ]; then
        echo "OK|$RULE_ID|LoginGraceTime is set to $CURRENT_VALUE seconds, which is acceptable (<= $REQUIRED_MAX_VALUE)."
        return 0
    else
        echo "WARN|$RULE_ID|LoginGraceTime is set to $CURRENT_VALUE seconds, expected value is $REQUIRED_MAX_VALUE or less."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
