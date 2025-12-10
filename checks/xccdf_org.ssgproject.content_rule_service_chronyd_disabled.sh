#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_chronyd_disabled"
TITLE="Ensure chrony.service is disabled and masked when chronyd is not selected"

run() {

    # Must be Debian-based
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian platform"
        return 0
    fi

    # linux-base must exist
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # chrony must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null \
        | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|chrony not installed"
        return 0
    fi

    # Read XCCDF variable
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    # Applies ONLY when chronyd is NOT selected
    if [[ "$var_timesync_service" == "chronyd" ]]; then
        echo "NOTAPPL|$RULE_ID|chronyd selected — chrony.service should remain active"
        return 0
    fi

    SYSTEMCTL=/usr/bin/systemctl

    # Check disabled
    if ! $SYSTEMCTL is-enabled chrony.service 2>/dev/null | grep -q disabled; then
        echo "WARN|$RULE_ID|chrony.service is not disabled"
        return 0
    fi

    # Check masked
    if ! $SYSTEMCTL is-enabled chrony.service 2>/dev/null | grep -q masked; then
        echo "WARN|$RULE_ID|chrony.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|chrony.service is disabled and masked as required"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi

