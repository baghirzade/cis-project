#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_openldap-clients_removed"
TITLE="Ensure ldap-utils package is removed"

run() {
    # Only for dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check ldap-utils installation
    if ! dpkg -s ldap-utils >/dev/null 2>&1; then
        echo "OK|$RULE_ID|ldap-utils package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|ldap-utils package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
