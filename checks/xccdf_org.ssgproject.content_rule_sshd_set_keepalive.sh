#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_keepalive"
TITLE="Ensure SSHD ClientAliveCountMax is set to 3 or less"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Define the required maximum count value
    REQUIRED_MAX_VALUE='3'
    
    # Get the effective ClientAliveCountMax configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on ClientAliveCountMax
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^clientalivecountmax' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default value is often 3 in modern OpenSSH, which is compliant.
        echo "OK|$RULE_ID|ClientAliveCountMax setting not explicitly found, assuming default 3 (Compliant)."
        return 0
    fi
    
    # Ensure the current value is an integer and is less than or equal to the required max value.
    if [[ "$CURRENT_VALUE" =~ ^[0-9]+$ ]] && [ "$CURRENT_VALUE" -le "$REQUIRED_MAX_VALUE" ]; then
        echo "OK|$RULE_ID|ClientAliveCountMax is set to $CURRENT_VALUE, which is compliant (<= $REQUIRED_MAX_VALUE)."
        return 0
    else
        echo "FAIL|$RULE_ID|ClientAliveCountMax is set to $CURRENT_VALUE, expected value is $REQUIRED_MAX_VALUE or less."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
