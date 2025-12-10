#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_rsh_removed"
TITLE="Ensure RSH client package (rsh-client) is removed"

run() {
    # Check if dpkg command exists
    if ! command -v dpkg &> /dev/null; then
        echo "NOTAPPL|$RULE_ID|dpkg command not found. Cannot check package status."
        return 0
    fi
    
    PACKAGE_NAME="rsh-client"

    # Check if the package is currently installed
    if dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "FAIL|$RULE_ID|Package $PACKAGE_NAME is installed. RSH uses unencrypted communication."
        return 1
    else
        echo "OK|$RULE_ID|Package $PACKAGE_NAME is not installed (Compliant)."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
