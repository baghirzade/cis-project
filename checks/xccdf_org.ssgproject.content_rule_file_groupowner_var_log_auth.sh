#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_auth"

run() {

    if [[ ! -e /var/log/auth.log ]]; then
        echo "NOTAPPL|$RULE_ID|/var/log/auth.log does not exist"
        return 0
    fi

    group=$(stat -c %G /var/log/auth.log)

    if [[ "$group" == "adm" || "$group" == "root" ]]; then
        echo "OK|$RULE_ID|Group owner is '$group'"
    else
        echo "WARN|$RULE_ID|Group owner is '$group' (expected: adm or root)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

