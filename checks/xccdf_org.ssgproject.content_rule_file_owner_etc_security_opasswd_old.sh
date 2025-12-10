#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_security_opasswd_old"

run() {

    # Ensure root user exists
    if ! id root >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|root user not present"
        return 0
    fi

    # File must exist
    if [[ ! -e /etc/security/opasswd.old ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/security/opasswd.old does not exist"
        return 0
    fi

    owner=$(stat -c %U /etc/security/opasswd.old 2>/dev/null)

    if [[ "$owner" == "root" ]]; then
        echo "OK|$RULE_ID|/etc/security/opasswd.old owner is root"
    else
        echo "WARN|$RULE_ID|owner is '$owner' (expected: root)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

