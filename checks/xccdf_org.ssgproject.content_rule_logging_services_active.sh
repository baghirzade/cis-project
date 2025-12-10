#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_logging_services_active"
TITLE="Logging services must be active (rsyslog or journald)"

run() {
    SYSTEMCTL_EXEC='/usr/bin/systemctl'

    # Check rsyslog
    if command -v dpkg >/dev/null 2>&1 && \
       dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
        if "$SYSTEMCTL_EXEC" is-active rsyslog.service >/dev/null 2>&1; then
            echo "OK|$RULE_ID|rsyslog.service is active"
            return 0
        else
            echo "WARN|$RULE_ID|rsyslog.service is installed but not active"
            return 0
        fi
    fi

    # Check journald
    if "$SYSTEMCTL_EXEC" is-active systemd-journald.service >/dev/null 2>&1; then
        echo "OK|$RULE_ID|systemd-journald.service is active"
        return 0
    fi

    echo "WARN|$RULE_ID|No logging service (rsyslog or journald) is active"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
