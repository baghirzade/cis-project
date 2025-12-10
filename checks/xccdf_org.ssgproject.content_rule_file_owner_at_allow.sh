#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_at_allow"

run() {

    # Applicability check
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/at.allow"

    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        exit 1
    fi

    EXPECTED_OWNER_UID="0"
    CURRENT_UID=$(stat -c "%u" "$FILE")

    if [ "$CURRENT_UID" != "$EXPECTED_OWNER_UID" ]; then
        echo "WARN|$RULE_ID|Incorrect owner UID ($CURRENT_UID), expected $EXPECTED_OWNER_UID"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct file owner (root)"
    exit 0
}

run
