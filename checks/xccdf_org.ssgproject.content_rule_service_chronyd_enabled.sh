#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_chronyd_enabled"
TITLE="Ensure chrony.service is enabled and running when chronyd is selected"

run() {
    # Only for Debian-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # linux-base must be present
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # chrony package must exist for rule to apply
    if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|chrony package not installed"
        return 0
    fi

    # Load XCCDF variable or default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    if [[ "$var_timesync_service" != "chronyd" ]]; then
        echo "NOTAPPL|$RULE_ID|chronyd not selected as timesync service"
        return 0
    fi

    SYSTEMCTL=/usr/bin/systemctl

    # Check if enabled
    if ! $SYSTEMCTL is-enabled chrony.service 2>/dev/null | grep -q enabled; then
        echo "WARN|$RULE_ID|chrony.service is not enabled"
        return 0
    fi

    # Check if running
    if ! $SYSTEMCTL is-active chrony.service 2>/dev/null | grep -q active; then
        echo "WARN|$RULE_ID|chrony.service is not running"
        return 0
    fi

    echo "OK|$RULE_ID|chrony.service is enabled and running"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
