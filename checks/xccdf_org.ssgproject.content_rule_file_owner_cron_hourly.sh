#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_cron_hourly"

run() {

    # Check applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|Rule not applicable (linux-base not installed)"
        exit 0
    fi

    # Directory must exist
    if [ ! -d /etc/cron.hourly ]; then
        echo "FAIL|$RULE_ID|Directory /etc/cron.hourly does not exist"
        exit 1
    fi

    OWNER_UID=$(stat -c %u /etc/cron.hourly 2>/dev/null)

    if [ "$OWNER_UID" = "0" ]; then
        echo "OK|$RULE_ID|Owner of /etc/cron.hourly is root (0)"
        exit 0
    else
        echo "FAIL|$RULE_ID|Owner UID=$OWNER_UID expected=0"
        exit 1
    fi
}

run
