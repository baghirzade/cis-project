#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_disable_host_auth"
TITLE="Ensure SSHD disables HostbasedAuthentication"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Define the required HostbasedAuthentication value
    REQUIRED_VALUE='no'
    
    # Get the effective HostbasedAuthentication configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on HostbasedAuthentication
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^hostbasedauthentication' | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
    REQUIRED_VALUE_UPPER=$(echo "$REQUIRED_VALUE" | tr '[:lower:]' '[:upper:]')

    # If the directive is not found, the default value is 'no' (compliant).
    # However, for CIS compliance, we ensure it's explicitly set or confirm the default.
    
    if [ -z "$CURRENT_VALUE" ]; then
        echo "FAIL|$RULE_ID|HostbasedAuthentication setting not explicitly found. Expected: $REQUIRED_VALUE."
        return 1
    fi
    
    # Check if the current value matches the required value (case-insensitive comparison)
    if [ "$CURRENT_VALUE" = "$REQUIRED_VALUE_UPPER" ]; then
        echo "OK|$RULE_ID|HostbasedAuthentication is correctly set to $REQUIRED_VALUE."
        return 0
    else
        echo "FAIL|$RULE_ID|HostbasedAuthentication is set to $CURRENT_VALUE, expected $REQUIRED_VALUE."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
