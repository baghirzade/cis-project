#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_cron_enabled"

run() {

    # Check platform applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|linux-base not installed, rule not applicable"
        exit 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # Check if service exists
    if ! $SYSTEMCTL list-unit-files cron.service >/dev/null 2>&1; then
        echo "FAIL|$RULE_ID|cron.service not found"
        exit 1
    fi

    # Check if enabled
    if $SYSTEMCTL is-enabled cron.service 2>/dev/null | grep -q "enabled"; then
        # Now also ensure running (if system is not offline)
        if [[ $($SYSTEMCTL is-system-running) == "offline" ]]; then
            echo "OK|$RULE_ID|cron service enabled (system offline)"
            exit 0
        fi

        if $SYSTEMCTL is-active cron.service >/dev/null 2>&1; then
            echo "OK|$RULE_ID|cron service enabled and running"
            exit 0
        else
            echo "FAIL|$RULE_ID|cron service enabled but NOT running"
            exit 1
        fi
    fi

    echo "FAIL|$RULE_ID|cron service NOT enabled"
    exit 1
}

run
