#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_enable_warning_banner_net"
TITLE="Ensure SSHD displays /etc/issue.net warning banner"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required Banner value
    REQUIRED_VALUE='/etc/issue.net'
    
    # Get the effective Banner configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on Banner
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^banner' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        echo "WARN|$RULE_ID|Banner setting not found in active sshd configuration."
        return 1
    fi
    
    # Check if the current value matches the required banner file path
    if [ "$CURRENT_VALUE" = "$REQUIRED_VALUE" ]; then
        echo "OK|$RULE_ID|Banner is correctly set to $CURRENT_VALUE."
        return 0
    else
        echo "WARN|$RULE_ID|Banner is set to $CURRENT_VALUE, expected $REQUIRED_VALUE."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
