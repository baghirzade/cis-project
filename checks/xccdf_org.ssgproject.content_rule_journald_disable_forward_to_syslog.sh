#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_journald_disable_forward_to_syslog"
TITLE="systemd-journald must not forward logs to syslog (ForwardToSyslog=no)"

run() {
    local CONF="/etc/systemd/journald.conf"

    # Only meaningful on Debian/Ubuntu-like systems with dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # SCAP remediation condition: linux-base and systemd must be installed, rsyslog must NOT be active
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (control not applicable)"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' 'systemd' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|systemd package is not installed (control not applicable)"
        return 0
    fi

    if systemctl is-active rsyslog >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is active (journald not sole logger; control not applicable)"
        return 0
    fi

    # Config file presence
    if [ ! -f "$CONF" ]; then
        echo "WARN|$RULE_ID|$CONF does not exist; ForwardToSyslog= is not explicitly configured (defaults may apply)"
        return 0
    fi

    # Extract the last effective (uncommented) ForwardToSyslog= value
    local last_value
    last_value="$(
        awk '
            /^[[:space:]]*#/ { next }                       # skip comments
            /^[[:space:]]*ForwardToSyslog[[:space:]]*=/ {
                line=$0
                sub(/^[[:space:]]*ForwardToSyslog[[:space:]]*=[[:space:]]*/, "", line)
                sub(/[[:space:]]+$/, "", line)
                val=line
            }
            END {
                if (val != "") print val;
            }
        ' "$CONF"
    )"

    if [ -z "$last_value" ]; then
        echo "WARN|$RULE_ID|ForwardToSyslog= is not set in $CONF (using default); expected explicit ForwardToSyslog=no"
        return 0
    fi

    shopt -s nocasematch
    if [[ "$last_value" == "no" ]]; then
        echo "OK|$RULE_ID|ForwardToSyslog=$last_value is explicitly configured in $CONF"
    else
        echo "WARN|$RULE_ID|ForwardToSyslog=$last_value is configured in $CONF; expected ForwardToSyslog=no"
    fi
    shopt -u nocasematch
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
