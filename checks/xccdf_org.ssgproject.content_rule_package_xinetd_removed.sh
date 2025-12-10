#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_xinetd_removed"
TITLE="Ensure xinetd package is removed"

run() {
    # Check platform applicability (using linux-base as proxy for Debian/Ubuntu)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|Platform check failed."
        return 0
    fi
    
    # Check if dpkg command exists
    if ! command -v dpkg &> /dev/null; then
        echo "FAIL|$RULE_ID|dpkg command not found. Cannot check package status."
        return 1
    fi
    
    PACKAGE_NAME="xinetd"

    # Check if the package is currently installed
    if dpkg-query --show --showformat='${db:Status-Status}' "$PACKAGE_NAME" 2>/dev/null | grep -q '^installed$'; then
        echo "FAIL|$RULE_ID|Package $PACKAGE_NAME is installed. xinetd is typically deprecated."
        return 1
    else
        echo "OK|$RULE_ID|Package $PACKAGE_NAME is not installed (Compliant)."
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
