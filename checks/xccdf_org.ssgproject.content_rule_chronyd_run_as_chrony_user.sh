#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_chronyd_run_as_chrony_user"
TITLE="Ensure chronyd runs as _chrony user"

run() {

    # Only Debian-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # chrony package must exist
    if ! dpkg-query --show --showformat='${db:Status-Status}' chrony \
        2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|chrony not installed"
        return 0
    fi

    config="/etc/chrony/chrony.conf"

    if [[ ! -f "$config" ]]; then
        echo "WARN|$RULE_ID|chrony.conf missing"
        return 0
    fi

    # Check for "user _chrony"
    if grep -Ei "^\s*user\s+_chrony\s*$" "$config" > /dev/null 2>&1; then
        echo "OK|$RULE_ID|chronyd configured to run as _chrony"
    else
        echo "WARN|$RULE_ID|chronyd not configured to run as _chrony"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
