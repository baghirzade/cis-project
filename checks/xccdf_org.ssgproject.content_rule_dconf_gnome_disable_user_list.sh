#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_disable_user_list"
TITLE="GNOME login screen user list must be disabled via dconf"

run() {
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|gdm3 is not installed (control not applicable)"
        return 0
    fi

    DCONF_DB_DIR="/etc/dconf/db"
    GDM_DIR="$DCONF_DB_DIR/gdm.d"
    LOCKS_DIR="$GDM_DIR/locks"

    if [ ! -d "$DCONF_DB_DIR" ]; then
        echo "WARN|$RULE_ID|$DCONF_DB_DIR does not exist; dconf configuration not found"
        return 0
    fi

    if ! grep -R "^\s*\[org/gnome/login-screen\]\s*$" "$GDM_DIR" >/dev/null 2>&1 || \
       ! grep -R "^\s*disable-user-list\s*=\s*true\s*$" "$GDM_DIR" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|disable-user-list=true is not configured for org/gnome/login-screen in $GDM_DIR"
        return 0
    fi

    if [ ! -d "$LOCKS_DIR" ] || \
       ! grep -R "^\s*/org/gnome/login-screen/disable-user-list\s*$" "$LOCKS_DIR" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|Lock for /org/gnome/login-screen/disable-user-list is not present in $LOCKS_DIR"
        return 0
    fi

    echo "OK|$RULE_ID|disable-user-list=true is configured and locked for org/gnome/login-screen (gdm dconf)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
