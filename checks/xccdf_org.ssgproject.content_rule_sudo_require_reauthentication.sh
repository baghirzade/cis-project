#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sudo_require_reauthentication"
TITLE="sudo must require reauthentication (timestamp_timeout=15 minutes)"

run() {
    REQUIRED_TIMEOUT="15"

    # Only Debian/Ubuntu systems have dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicability: only when linux-base is installed (same as SCAP)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (rule not applicable)"
        return 0
    fi

    # Only relevant when sudo is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|sudo is not installed (rule not applicable)"
        return 0
    fi

    if [ ! -x /usr/sbin/visudo ]; then
        echo "FAIL|$RULE_ID|/usr/sbin/visudo not found; cannot safely validate sudoers"
        return 0
    fi

    # Validate main sudoers
    if ! /usr/sbin/visudo -qcf /etc/sudoers; then
        echo "FAIL|$RULE_ID|/etc/sudoers is invalid according to visudo"
        return 0
    fi

    # -------------------------
    # Check timestamp_timeout in /etc/sudoers.d/*
    # -------------------------
    if [ -d /etc/sudoers.d ]; then
        if grep -P '^(?!#)[[:space:]]*Defaults.*timestamp_timeout[[:space:]]*=' /etc/sudoers.d/* 2>/dev/null; then
            echo "WARN|$RULE_ID|timestamp_timeout is configured in /etc/sudoers.d; it should only be defined centrally in /etc/sudoers"
            return 0
        fi
    fi

    # -------------------------
    # Check timestamp_timeout in /etc/sudoers
    # -------------------------
    if ! grep -P '^[\s]*Defaults.*timestamp_timeout[\s]*=' /etc/sudoers >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|timestamp_timeout is not configured in /etc/sudoers (expected Defaults timestamp_timeout=${REQUIRED_TIMEOUT})"
        return 0
    fi

    # Extract current value (first match)
    current_value="$(grep -P '^[\s]*Defaults.*timestamp_timeout[\s]*=' /etc/sudoers \
        | awk -F'timestamp_timeout' '{print $2}' \
        | awk -F'=' '{print $2}' \
        | awk '{print $1}' \
        | head -n1)"

    # Strip possible leading/trailing spaces
    current_value="$(echo "$current_value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

    if [ "$current_value" != "$REQUIRED_TIMEOUT" ]; then
        echo "WARN|$RULE_ID|timestamp_timeout is configured as '${current_value}', expected '${REQUIRED_TIMEOUT}'"
        return 0
    fi

    echo "OK|$RULE_ID|timestamp_timeout is configured as ${REQUIRED_TIMEOUT} minutes in /etc/sudoers and not overridden in /etc/sudoers.d"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
