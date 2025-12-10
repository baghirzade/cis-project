#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_cron_daily"

run() {

    # Check applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    # Check directory exists
    if [ ! -d /etc/cron.daily ]; then
        echo "FAIL|$RULE_ID|/etc/cron.daily missing"
        exit 1
    fi

    # Check group owner
    GID=$(stat -c %g /etc/cron.daily 2>/dev/null)
    if [ "$GID" = "0" ]; then
        echo "OK|$RULE_ID|Group owner of /etc/cron.daily is root (0)"
        exit 0
    else
        echo "FAIL|$RULE_ID|Group owner of /etc/cron.daily is $GID, expected 0"
        exit 1
    fi
}

run
