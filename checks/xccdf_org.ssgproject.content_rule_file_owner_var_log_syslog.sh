#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_syslog"

run() {

    target="/var/log/syslog"

    if [[ ! -f "$target" ]]; then
        echo "NOTAPPL|$RULE_ID|/var/log/syslog not found"
        exit 0
    fi

    owner=$(stat -c %U "$target")

    if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
        echo "OK|$RULE_ID|$target owner '$owner' is compliant"
        exit 0
    else
        echo "WARN|$RULE_ID|$target owner '$owner' is NOT compliant (expected syslog or root)"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

