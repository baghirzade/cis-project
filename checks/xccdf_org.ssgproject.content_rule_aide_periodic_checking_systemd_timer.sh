#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_aide_periodic_checking_systemd_timer"
TITLE="AIDE periodic checking must be configured via systemd timer"

run() {
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (control not applicable)"
        return 0
    fi

    if ! dpkg -s aide >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|AIDE package is not installed (timer cannot be used yet)"
        return 0
    fi

    if ! dpkg -s systemd >/dev/null 2>&1 || ! command -v systemctl >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|systemd/systemctl not available (control not applicable)"
        return 0
    fi

    if ! systemctl list-unit-files dailyaidecheck.timer >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|dailyaidecheck.timer unit is not present"
        return 0
    fi

    if ! systemctl is-enabled dailyaidecheck.timer >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|dailyaidecheck.timer is not enabled"
        return 0
    fi

    if ! systemctl is-active dailyaidecheck.timer >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|dailyaidecheck.timer is enabled but not active"
        return 0
    fi

    echo "OK|$RULE_ID|AIDE periodic checking is configured via dailyaidecheck.timer (enabled and active)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
