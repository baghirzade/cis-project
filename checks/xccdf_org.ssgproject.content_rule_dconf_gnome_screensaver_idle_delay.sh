#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_screensaver_idle_delay"
TITLE="GNOME screensaver idle delay must be configured (idle-delay=uint32 900 and locked)"

run() {
    DCONF_DB_DIR="/etc/dconf/db"
    LOCAL_DIR="$DCONF_DB_DIR/local.d"
    LOCKS_DIR="$LOCAL_DIR/locks"

    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicable only if gdm3 is installed (per SCAP logic)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|gdm3 is not installed (control not applicable)"
        return 0
    fi

    # dconf db must exist
    if [ ! -d "$DCONF_DB_DIR" ]; then
        echo "WARN|$RULE_ID|$DCONF_DB_DIR does not exist; dconf configuration not found"
        return 0
    fi

    if [ ! -d "$LOCAL_DIR" ]; then
        echo "WARN|$RULE_ID|$LOCAL_DIR does not exist; no local.d dconf configuration"
        return 0
    fi

    # Check settings: [org/gnome/desktop/session] + idle-delay=uint32 900 in local.d
    if ! grep -R "^\s*\[org/gnome/desktop/session\]\s*$" "$LOCAL_DIR" >/dev/null 2>&1 || \
       ! grep -R "^\s*idle-delay\s*=\s*uint32 900\s*$" "$LOCAL_DIR" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|idle-delay=uint32 900 is not configured under [org/gnome/desktop/session] in $LOCAL_DIR"
        return 0
    fi

    # Check locks
    if [ ! -d "$LOCKS_DIR" ] || \
       ! grep -R "^\s*/org/gnome/desktop/session/idle-delay\s*$" "$LOCKS_DIR" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|Lock for /org/gnome/desktop/session/idle-delay is not present in $LOCKS_DIR"
        return 0
    fi

    echo "OK|$RULE_ID|idle-delay=uint32 900 is configured and locked for org/gnome/desktop/session (local dconf)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
