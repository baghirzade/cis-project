#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_cron_allow"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/cron.allow"

    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        exit 1
    fi

    EXPECTED_GROUP="crontab"

    GROUP_OWNER_NAME=$(stat -c "%G" "$FILE")

    if [ "$GROUP_OWNER_NAME" != "$EXPECTED_GROUP" ]; then
        echo "WARN|$RULE_ID|Incorrect group owner ($GROUP_OWNER_NAME), expected $EXPECTED_GROUP"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct group owner ($EXPECTED_GROUP)"
    exit 0
}

run
