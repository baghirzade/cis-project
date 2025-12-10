#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_maxstartups"
TITLE="Ensure SSHD MaxStartups is set correctly"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required MaxStartups value (the standard CIS benchmark value)
    REQUIRED_VALUE='10:30:60'
    
    # Get the effective MaxStartups configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "WARN|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on MaxStartups
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^maxstartups' | awk '{print $2}')

    if [ -z "$CURRENT_VALUE" ]; then
        echo "WARN|$RULE_ID|MaxStartups setting not found in active sshd configuration."
        return 1
    fi

    # MaxStartups format is <start>:<rate>:<full>
    # The check is often simplified to ensure the value is set and not excessively large.
    # For compliance, we check if the value is exactly the required one.
    if [ "$CURRENT_VALUE" = "$REQUIRED_VALUE" ]; then
        echo "OK|$RULE_ID|MaxStartups is correctly set to $CURRENT_VALUE."
        return 0
    else
        # Perform a stricter check to ensure that the values are not more permissive
        # than the recommended 10:30:60.
        # This requires numerical comparison, but the simplest compliance check looks for the exact recommended value.
        echo "WARN|$RULE_ID|MaxStartups is set to $CURRENT_VALUE, expected $REQUIRED_VALUE."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
