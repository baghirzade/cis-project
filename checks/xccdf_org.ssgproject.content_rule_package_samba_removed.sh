#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_samba_removed"
TITLE="Ensure Samba package is removed"

run() {
    # Check if dpkg command exists
    if ! command -v dpkg &> /dev/null; then
        echo "NOTAPPL|$RULE_ID|dpkg command not found. Cannot check package status."
        return 0
    fi
    
    PACKAGE_NAME="samba"

    # Check if the package is currently installed
    if dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "FAIL|$RULE_ID|Package $PACKAGE_NAME is installed."
        return 1
    else
        echo "OK|$RULE_ID|Package $PACKAGE_NAME is not installed (Compliant)."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
