#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_cron_allow"

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

    # Required permissions → chmod u-xs,g-xws,o-xwrt = 0600
    EXPECTED_MODE="600"
    CURRENT_MODE=$(stat -c "%a" "$FILE")

    if [ "$CURRENT_MODE" != "$EXPECTED_MODE" ]; then
        echo "WARN|$RULE_ID|Incorrect permissions $CURRENT_MODE, expected $EXPECTED_MODE"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct permissions on $FILE"
    exit 0
}

run
