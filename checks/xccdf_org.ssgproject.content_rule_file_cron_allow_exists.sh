#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_cron_allow_exists"

run() {

    # Check applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    FILE="/etc/cron.allow"

    # File existence check
    if [ ! -f "$FILE" ]; then
        echo "WARN|$RULE_ID|$FILE does NOT exist"
        exit 1
    fi

    # Owner check
    OWNER=$(stat -c %u "$FILE")
    if [ "$OWNER" -ne 0 ]; then
        echo "WARN|$RULE_ID|Incorrect owner on $FILE (owner=$OWNER, expected=0)"
        exit 1
    fi

    # Permission check
    PERM=$(stat -c %a "$FILE")
    if [ "$PERM" != "600" ]; then
        echo "WARN|$RULE_ID|Incorrect permissions on $FILE (perm=$PERM, expected=600)"
        exit 1
    fi

    echo "OK|$RULE_ID|$FILE exists with correct owner & permissions"
    exit 0
}

run
