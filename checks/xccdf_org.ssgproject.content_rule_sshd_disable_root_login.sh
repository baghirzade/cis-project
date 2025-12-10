#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_disable_root_login"
TITLE="Ensure SSHD prohibits root login"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Define the required PermitRootLogin value
    REQUIRED_VALUE='no'
    
    # Get the effective PermitRootLogin configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on PermitRootLogin
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^permitrootlogin' | awk '{print $2}' | tr '[:lower:]' '[:upper:]')
    REQUIRED_VALUE_UPPER=$(echo "$REQUIRED_VALUE" | tr '[:lower:]' '[:upper:]')

    # If the directive is not found, the default value is often 'prohibit-password' or 'yes'.
    # For compliance, it must be explicitly set to 'no' or 'prohibit-password'/'forced-commands-only'.
    
    if [ -z "$CURRENT_VALUE" ]; then
        echo "WARN|$RULE_ID|PermitRootLogin setting not explicitly found. Expected: $REQUIRED_VALUE."
        return 1
    fi
    
    # Check if the current value denies root access (no, prohibit-password, or forced-commands-only)
    if [ "$CURRENT_VALUE" = "NO" ] || [ "$CURRENT_VALUE" = "PROHIBIT-PASSWORD" ] || [ "$CURRENT_VALUE" = "FORCED-COMMANDS-ONLY" ]; then
        echo "OK|$RULE_ID|PermitRootLogin is set to $CURRENT_VALUE, which effectively denies/limits direct root login."
        return 0
    else
        echo "WARN|$RULE_ID|PermitRootLogin is set to $CURRENT_VALUE, expected $REQUIRED_VALUE or a more secure setting."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
