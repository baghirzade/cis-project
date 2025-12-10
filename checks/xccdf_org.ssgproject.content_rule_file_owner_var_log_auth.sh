#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_auth"

run() {

    f="/var/log/auth.log"

    if [[ ! -f "$f" ]]; then
        echo "NOTAPPL|$RULE_ID|$f does not exist"
        exit 0
    fi

    owner=$(stat -c %U "$f")

    if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
        echo "OK|$RULE_ID|$f owner '$owner' is compliant"
        exit 0
    else
        echo "WARN|$RULE_ID|$f has noncompliant owner '$owner' (expected: syslog or root)"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

