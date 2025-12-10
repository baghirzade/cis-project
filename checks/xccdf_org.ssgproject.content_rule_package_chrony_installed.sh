#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_chrony_installed"
TITLE="Ensure chrony is installed when chronyd is selected as time sync service"

run() {
    # Must be Debian-based system
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # Rule applies only if linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # Read var_timesync_service from environment if provided, else default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    if [[ "$var_timesync_service" != "chronyd" ]]; then
        echo "NOTAPPL|$RULE_ID|Time sync service is not chronyd"
        return 0
    fi

    # Now chrony must be installed
    if dpkg -s chrony >/dev/null 2>&1; then
        echo "OK|$RULE_ID|chrony is installed"
    else
        echo "FAIL|$RULE_ID|chrony must be installed when chronyd is selected"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
