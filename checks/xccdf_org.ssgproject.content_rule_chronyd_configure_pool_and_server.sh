#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_chronyd_configure_pool_and_server"
TITLE="Ensure chrony servers and pools are configured"

run() {

    # Debian applicability
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Not a Debian-based system"
        return 0
    fi

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # chrony must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' chrony \
        2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|chrony not installed"
        return 0
    fi

    config_file="/etc/chrony/chrony.conf"

    if [[ ! -f "$config_file" ]]; then
        echo "WARN|$RULE_ID|chrony.conf missing"
        return 0
    fi

    # XCCDF variables
    var_multiple_time_servers="${var_multiple_time_servers:-0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org}"
    var_multiple_time_pools="${var_multiple_time_pools:-0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org}"

    IFS=',' read -ra SERVERS <<< "$var_multiple_time_servers"
    IFS=',' read -ra POOLS <<< "$var_multiple_time_pools"

    missing=0

    # Check servers
    for srv in "${SERVERS[@]}"; do
        if ! grep -Eq "^\s*server\s+$srv(\s|$)" "$config_file"; then
            echo "WARN|$RULE_ID|Missing server entry: $srv"
            missing=1
        fi
    done

    # Check pools
    for srv in "${POOLS[@]}"; do
        if ! grep -Eq "^\s*pool\s+$srv(\s|$)" "$config_file"; then
            echo "WARN|$RULE_ID|Missing pool entry: $srv"
            missing=1
        fi
    done

    if [[ $missing -eq 0 ]]; then
        echo "OK|$RULE_ID|All chrony server and pool entries are configured"
    else
        echo "WARN|$RULE_ID|Some chrony server or pool entries are missing"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi