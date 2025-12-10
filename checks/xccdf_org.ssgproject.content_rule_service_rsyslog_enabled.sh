#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_rsyslog_enabled"
TITLE="Rsyslog service must be enabled and running"

run() {
    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check if rsyslog package is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|rsyslog package is not installed (service not applicable)"
        return 0
    fi

    SYSTEMCTL_EXEC='/usr/bin/systemctl'

    # Check if service is enabled
    if ! "$SYSTEMCTL_EXEC" is-enabled rsyslog.service >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|rsyslog.service is not enabled"
        return 0
    fi

    # Check if service is active
    if ! "$SYSTEMCTL_EXEC" is-active rsyslog.service >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|rsyslog.service is not running"
        return 0
    fi

    echo "OK|$RULE_ID|rsyslog.service is enabled and running"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
