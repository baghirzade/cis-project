#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_journald_compress"
TITLE="systemd-journald must be configured to compress journals (Compress=yes)"

run() {
    local journald_conf="/etc/systemd/journald.conf"

    # Only Debian/Ubuntu systems with dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Control is only applicable when linux-base package is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (rule not applicable)"
        return 0
    fi

    # In SCAP logic this rule is only applied when rsyslog is NOT active
    # (journald is primary logger). If rsyslog is active, treat as not applicable.
    if systemctl is-active rsyslog >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is active (journald-only logging not in use)"
        return 0
    fi

    # journald.conf presence
    if [ ! -f "$journald_conf" ]; then
        echo "WARN|$RULE_ID|$journald_conf does not exist; Compress=yes is not explicitly configured"
        return 0
    fi

    # Find any active (non-commented) Compress= line
    local compress_line value

    compress_line="$(grep -E '^[[:space:]]*Compress[[:space:]]*=' "$journald_conf" 2>/dev/null | head -n1 || true)"

    if [ -z "$compress_line" ]; then
        echo "WARN|$RULE_ID|No active Compress= line found in $journald_conf; journald compression is not explicitly enabled"
        return 0
    fi

    # Extract value right of '=' and trim spaces
    value="$(printf '%s\n' "$compress_line" | sed -E 's/^[[:space:]]*Compress[[:space:]]*=[[:space:]]*//; s/[[:space:]]+$//')"

    # Normalize case
    value="$(printf '%s' "$value" | tr 'A-Z' 'a-z')"

    if [ "$value" = "yes" ]; then
        echo "OK|$RULE_ID|Compress=yes is configured in $journald_conf"
    else
        echo "WARN|$RULE_ID|Compress is set to '$value' in $journald_conf (expected: yes)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
