#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_idle_timeout"
TITLE="Ensure SSHD ClientAliveInterval is set to 300 seconds or less"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Define the required maximum idle timeout value in seconds
    REQUIRED_MAX_VALUE='300'
    
    # Get the effective ClientAliveInterval configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on ClientAliveInterval
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^clientaliveinterval' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default is 0 (no timeout). Must be explicitly set for compliance.
        echo "WARN|$RULE_ID|ClientAliveInterval setting not found in active sshd configuration."
        return 1
    fi
    
    # Ensure the current value is an integer and is less than or equal to the required max value.
    if [[ "$CURRENT_VALUE" =~ ^[0-9]+$ ]] && [ "$CURRENT_VALUE" -gt 0 ] && [ "$CURRENT_VALUE" -le "$REQUIRED_MAX_VALUE" ]; then
        echo "OK|$RULE_ID|ClientAliveInterval is set to $CURRENT_VALUE seconds, which is compliant (0 < value <= $REQUIRED_MAX_VALUE)."
        return 0
    elif [ "$CURRENT_VALUE" = "0" ]; then
        echo "WARN|$RULE_ID|ClientAliveInterval is set to 0 (disabled). Expected value 1 to $REQUIRED_MAX_VALUE."
        return 1
    else
        echo "WARN|$RULE_ID|ClientAliveInterval is set to $CURRENT_VALUE seconds, expected value is $REQUIRED_MAX_VALUE or less (and greater than 0)."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
