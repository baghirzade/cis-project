#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_cron_deny_not_exist"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/cron.deny"

    if [ -f "$FILE" ]; then
        echo "FAIL|$RULE_ID|$FILE exists, but it should NOT exist"
        exit 1
    fi

    echo "OK|$RULE_ID|$FILE does not exist as required"
    exit 0
}

run
