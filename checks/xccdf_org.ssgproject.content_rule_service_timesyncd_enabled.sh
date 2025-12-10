#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_enabled"
TITLE="Ensure systemd-timesyncd.service is enabled and running when selected"

run() {

    # System must be Debian-based
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # Rule applies only if chrony *and* ntp are NOT installed
    if dpkg -s chrony >/dev/null 2>&1 || dpkg -s ntp >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|chrony or ntp installed; timesyncd not required"
        return 0
    fi

    # Read XCCDF variable or default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    if [[ "$var_timesync_service" != "systemd-timesyncd" ]]; then
        echo "NOTAPPL|$RULE_ID|Time sync service is not systemd-timesyncd"
        return 0
    fi

    SYSTEMCTL=/usr/bin/systemctl

    # Check enabled
    if ! $SYSTEMCTL is-enabled systemd-timesyncd.service 2>/dev/null | grep -q enabled; then
        echo "FAIL|$RULE_ID|systemd-timesyncd.service is not enabled"
        return 0
    fi

    # Check active
    if ! $SYSTEMCTL is-active systemd-timesyncd.service 2>/dev/null | grep -q active; then
        echo "FAIL|$RULE_ID|systemd-timesyncd.service is not running"
        return 0
    fi

    echo "OK|$RULE_ID|systemd-timesyncd.service is enabled and running"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

