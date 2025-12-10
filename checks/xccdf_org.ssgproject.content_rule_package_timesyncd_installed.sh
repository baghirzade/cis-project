#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_timesyncd_installed"
TITLE="Ensure systemd-timesyncd is installed when selected as the time sync service"

run() {
    # Must be a Debian-based system
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # Rule applies only if linux-base exists
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q "^installed$"; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # Read XCCDF variable or fallback to default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    if [[ "$var_timesync_service" != "systemd-timesyncd" ]]; then
        echo "NOTAPPL|$RULE_ID|Time sync service is not systemd-timesyncd"
        return 0
    fi

    # Check installation
    if dpkg -s systemd-timesyncd >/dev/null 2>&1; then
        echo "OK|$RULE_ID|systemd-timesyncd is installed"
    else
        echo "FAIL|$RULE_ID|systemd-timesyncd must be installed when selected"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
