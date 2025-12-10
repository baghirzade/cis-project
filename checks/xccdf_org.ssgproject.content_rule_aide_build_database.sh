#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_aide_build_database"
TITLE="AIDE database must be initialized and configured"

run() {
    AIDE_CONFIG="/etc/aide/aide.conf"
    DEFAULT_DB_PATH="/var/lib/aide/aide.db"

    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (control not applicable)"
        return 0
    fi

    if ! dpkg -s aide >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|AIDE package is not installed (database cannot be initialized yet)"
        return 0
    fi

    if [ ! -f "$AIDE_CONFIG" ]; then
        echo "WARN|$RULE_ID|AIDE config file not found at $AIDE_CONFIG"
        return 0
    fi

    if ! grep -q '^database=file:' "$AIDE_CONFIG"; then
        echo "WARN|$RULE_ID|AIDE config does not define 'database=file:' entry"
        return 0
    fi

    if ! grep -q '^database_out=file:' "$AIDE_CONFIG"; then
        echo "WARN|$RULE_ID|AIDE config does not define 'database_out=file:' entry"
        return 0
    fi

    if [ ! -f "$DEFAULT_DB_PATH" ]; then
        echo "WARN|$RULE_ID|AIDE database file is missing at $DEFAULT_DB_PATH"
        return 0
    fi

    echo "OK|$RULE_ID|AIDE database is configured and present at $DEFAULT_DB_PATH"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
