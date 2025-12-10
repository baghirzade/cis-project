#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_configured"
TITLE="Ensure systemd-timesyncd is configured with multiple time servers"

run() {

    # Applicability checks
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' systemd 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|systemd not installed"
        return 0
    fi

    if ! command -v timedatectl >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|timedatectl command missing"
        return 1
    fi

    # Expected values from remediation
    VAR_MULTIPLE_TIME_SERVERS='0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org'
    IFS=',' read -ra servers <<< "$VAR_MULTIPLE_TIME_SERVERS"

    expected_ntp="${servers[0]},${servers[1]}"
    expected_fallback="${servers[2]},${servers[3]}"

    # Read effective system state
    current_ntp=$(timedatectl show-timesync --property=NTP --value 2>/dev/null | tr ' ' ',' | sed 's/,$//')
    current_fallback=$(timedatectl show-timesync --property=FallbackNTP --value 2>/dev/null | tr ' ' ',' | sed 's/,$//')

    msg=""
    fail=0

    if [[ "$current_ntp" != *"$expected_ntp"* ]]; then
        msg+="Missing preferred servers (expected $expected_ntp, got $current_ntp). "
        fail=1
    fi

    if [[ "$current_fallback" != *"$expected_fallback"* ]]; then
        msg+="Missing fallback servers (expected $expected_fallback, got $current_fallback). "
        fail=1
    fi

    if [[ $fail -eq 0 ]]; then
        echo "OK|$RULE_ID|systemd-timesyncd is correctly configured"
        return 0
    fi

    # FAIL output MUST include a non-empty message!
    echo "WARN|$RULE_ID|$msg"
    return 1
}

[[ "${BASH_SOURCE[0]}" == "$0" ]] && run
