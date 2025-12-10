#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_at_allow"

run() {

    # Applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/at.allow"

    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does not exist"
        exit 1
    fi

    # Group owner must be 0 (root)
    GROUP_OWNER=$(stat -c "%g" "$FILE")

    if [ "$GROUP_OWNER" != "0" ]; then
        echo "WARN|$RULE_ID|Incorrect group owner ($GROUP_OWNER), expected 0"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct group owner (0)"
    exit 0
}

run
