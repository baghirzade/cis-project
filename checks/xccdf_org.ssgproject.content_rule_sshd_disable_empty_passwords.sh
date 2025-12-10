#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_disable_empty_passwords"
TITLE="Ensure SSHD prohibits empty passwords"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Define the required PermitEmptyPasswords value
    REQUIRED_VALUE='no'
    
    # Get the effective PermitEmptyPasswords configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on PermitEmptyPasswords
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^permitemptypasswords' | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
    REQUIRED_VALUE_UPPER=$(echo "$REQUIRED_VALUE" | tr '[:lower:]' '[:upper:]')

    # If the directive is not found, the default value is 'no' (compliant).
    # However, for CIS compliance, we ensure it's explicitly set.
    
    if [ -z "$CURRENT_VALUE" ] || [ "$CURRENT_VALUE" != "$REQUIRED_VALUE_UPPER" ]; then
        # Check if it's explicitly set to 'no'
        if grep -qP '^\s*PermitEmptyPasswords\s+no\s*$' /etc/ssh/sshd_config /etc/ssh/sshd_config.d/*.conf 2>/dev/null; then
            echo "OK|$RULE_ID|PermitEmptyPasswords is explicitly set to $REQUIRED_VALUE."
            return 0
        fi
        
        # If it's not explicitly 'no' and not found by sshd -T, we fail for non-explicit setting.
        if [ "$CURRENT_VALUE" != "$REQUIRED_VALUE_UPPER" ]; then
             echo "FAIL|$RULE_ID|PermitEmptyPasswords is not correctly set to $REQUIRED_VALUE (current effective value: $CURRENT_VALUE)."
             return 1
        fi
    fi
    
    # Check if the current value matches the required value (if found by sshd -T)
    if [ "$CURRENT_VALUE" = "$REQUIRED_VALUE_UPPER" ]; then
        echo "OK|$RULE_ID|PermitEmptyPasswords is correctly set to $REQUIRED_VALUE."
        return 0
    fi
    
    return 1 # Fallback fail
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
