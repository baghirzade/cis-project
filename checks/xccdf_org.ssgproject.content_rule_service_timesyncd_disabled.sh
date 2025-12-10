#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_disabled"
TITLE="Ensure systemd-timesyncd.service is disabled and masked when not selected"

run() {

    # Must be Debian-based
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # systemd-timesyncd must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' systemd-timesyncd 2>/dev/null \
        | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|systemd-timesyncd not installed"
        return 0
    fi

    # Retrieve XCCDF variable or use default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    # Rule applies ONLY if the service should NOT be systemd-timesyncd
    if [[ "$var_timesync_service" == "systemd-timesyncd" ]]; then
        echo "NOTAPPL|$RULE_ID|systemd-timesyncd is selected (should remain enabled)"
        return 0
    fi

    SYSTEMCTL=/usr/bin/systemctl

    # Check disabled
    if ! $SYSTEMCTL is-enabled systemd-timesyncd.service 2>/dev/null | grep -q disabled; then
        echo "FAIL|$RULE_ID|systemd-timesyncd.service is not disabled"
        return 0
    fi

    # Check masked
    if ! $SYSTEMCTL is-enabled systemd-timesyncd.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|systemd-timesyncd.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|systemd-timesyncd.service is disabled and masked as required"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

