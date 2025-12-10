#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_at_deny"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/at.deny"

    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        exit 1
    fi

    # Required permissions → chmod u-xs,g-xws,o-xwrt = 0640
    EXPECTED_MODE="640"
    CURRENT_MODE=$(stat -c "%a" "$FILE")

    if [ "$CURRENT_MODE" != "$EXPECTED_MODE" ]; then
        echo "WARN|$RULE_ID|Incorrect permissions $CURRENT_MODE, expected $EXPECTED_MODE"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct permissions on $FILE"
    exit 0
}

run
