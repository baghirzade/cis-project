#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_at_allow"

run() {

    # Rule applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/at.allow"

    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        exit 1
    fi

    # Expected permissions: 0640 or stricter
    # The remediation sets: u-xs,g-xws,o-xwrt → effectively 0640  
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
