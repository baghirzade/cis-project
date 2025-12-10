#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_messages"

run() {

    file="/var/log/messages"

    if [[ ! -f "$file" ]]; then
        echo "NOTAPPL|$RULE_ID|/var/log/messages does not exist"
        exit 0
    fi

    grp=$(stat -c %G "$file")

    if [[ "$grp" == "adm" || "$grp" == "root" ]]; then
        echo "OK|$RULE_ID|$file group '$grp' is compliant"
        exit 0
    else
        echo "WARN|$RULE_ID|$file has non-compliant group '$grp' (expected: adm or root)"
        exit 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

