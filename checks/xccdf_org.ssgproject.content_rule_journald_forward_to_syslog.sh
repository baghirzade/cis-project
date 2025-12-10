#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_journald_forward_to_syslog"
TITLE="journald must forward logs to syslog when rsyslog is active (ForwardToSyslog=yes)"

run() {
    JOURNALD_CONF="/etc/systemd/journald.conf"

    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicable only if linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (control not applicable)"
        return 0
    fi

    # Applicable only if rsyslog is active (per remediation logic)
    if ! systemctl is-active rsyslog &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is not active (control not applicable)"
        return 0
    fi

    # journald.conf presence
    if [ ! -f "$JOURNALD_CONF" ]; then
        echo "WARN|$RULE_ID|$JOURNALD_CONF does not exist; ForwardToSyslog=yes not explicitly configured while rsyslog is active"
        return 0
    fi

    # Check ForwardToSyslog=yes (uncommented)
    if grep -Eq '^[[:space:]]*ForwardToSyslog[[:space:]]*=[[:space:]]*yes[[:space:]]*$' "$JOURNALD_CONF"; then
        echo "OK|$RULE_ID|ForwardToSyslog=yes is explicitly set in $JOURNALD_CONF while rsyslog is active"
        return 0
    fi

    # If any other ForwardToSyslog setting exists, report that it is not 'yes'
    if grep -Eq '^[[:space:]]*ForwardToSyslog[[:space:]]*=' "$JOURNALD_CONF"; then
        echo "WARN|$RULE_ID|ForwardToSyslog is set but not to 'yes' in $JOURNALD_CONF while rsyslog is active"
        return 0
    fi

    # No ForwardToSyslog line at all
    echo "WARN|$RULE_ID|ForwardToSyslog is not explicitly set to 'yes' in $JOURNALD_CONF while rsyslog is active"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
