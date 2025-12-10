#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_security_opasswd"

run() {

    # Ensure root group exists
    if ! getent group root >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|root group not present"
        return 0
    fi

    # Check file exists
    if [[ ! -e /etc/security/opasswd ]]; then
        echo "NOTAPPL|$RULE_ID|/etc/security/opasswd does not exist"
        return 0
    fi

    grp=$(stat -c %G /etc/security/opasswd 2>/dev/null)

    if [[ "$grp" == "root" ]]; then
        echo "OK|$RULE_ID|/etc/security/opasswd group owner is root"
    else
        echo "WARN|$RULE_ID|group owner is '$grp' (expected: root)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

