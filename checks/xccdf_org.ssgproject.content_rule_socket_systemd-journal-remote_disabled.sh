#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_socket_systemd-journal-remote_disabled"
TITLE="systemd-journal-remote socket must be disabled"

run() {
    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicable only if linux-base is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (control not applicable)"
        return 0
    fi

    SYSTEMCTL_EXEC='/usr/bin/systemctl'
    SOCKET_NAME="systemd-journal-remote.socket"

    if ! "$SYSTEMCTL_EXEC" -q list-unit-files --type socket | grep -q "$SOCKET_NAME"; then
        echo "NOTAPPL|$RULE_ID|$SOCKET_NAME not present on system"
        return 0
    fi

    # Check if masked
    if "$SYSTEMCTL_EXEC" is-enabled "$SOCKET_NAME" 2>/dev/null | grep -q 'masked'; then
        echo "OK|$RULE_ID|$SOCKET_NAME is masked (disabled)"
        return 0
    fi

    echo "WARN|$RULE_ID|$SOCKET_NAME is present but not masked/disabled"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
