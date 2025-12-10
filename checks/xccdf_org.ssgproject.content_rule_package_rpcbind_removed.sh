#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_rpcbind_removed"
TITLE="Ensure rpcbind package is removed"

run() {

    # dpkg required
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg unavailable (non-Debian system)"
        return 0
    fi

    # Rule applicability: linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
       | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed, rule not applicable"
        return 0
    fi

    # Check if rpcbind installed
    if ! dpkg -s rpcbind >/dev/null 2>&1; then
        echo "OK|$RULE_ID|rpcbind package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|rpcbind package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
