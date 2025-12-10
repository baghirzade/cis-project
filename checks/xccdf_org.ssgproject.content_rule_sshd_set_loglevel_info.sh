#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sshd_set_loglevel_info"
TITLE="Ensure SSHD LogLevel is set to INFO or higher"

run() {
    # Check platform applicability
    if ! command -v dpkg &> /dev/null || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi

    # Define the required minimum LogLevel
    REQUIRED_LEVEL='INFO'
    
    # Get the effective LogLevel configuration from sshd config files
    if ! command -v sshd &> /dev/null; then
        echo "FAIL|$RULE_ID|sshd command not found. Cannot determine configuration."
        return 1
    fi
    
    # Use sshd -T to parse the effective configuration, focusing on LogLevel
    CURRENT_VALUE=$(sshd -T 2>/dev/null | grep -i '^loglevel' | awk '{print $2}' | tr '[:lower:]' '[:upper:]')

    if [ -z "$CURRENT_VALUE" ]; then
        # Default LogLevel is often "VERBOSE" or "INFO". If not found, it is non-compliant as it is not explicitly set.
        echo "FAIL|$RULE_ID|LogLevel setting not found in active sshd configuration."
        return 1
    fi
    
    # Log levels ordered from least detailed (highest security priority) to most detailed (lowest security priority):
    # FATAL, QUIET, ERROR, INFO (default in older versions), VERBOSE, DEBUG, DEBUG1, DEBUG2, DEBUG3
    # We check if the current level is INFO or more detailed (VERBOSE, DEBUG*)

    # Simple check for compliance: ensure it is INFO or greater.
    if [ "$CURRENT_VALUE" = "INFO" ] || \
       [ "$CURRENT_VALUE" = "VERBOSE" ] || \
       [[ "$CURRENT_VALUE" =~ ^DEBUG[1-3]*$ ]]
    then
        echo "OK|$RULE_ID|LogLevel is set to $CURRENT_VALUE, which meets or exceeds the required INFO level."
        return 0
    else
        echo "FAIL|$RULE_ID|LogLevel is set to $CURRENT_VALUE, which is less detailed than the required INFO level."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
