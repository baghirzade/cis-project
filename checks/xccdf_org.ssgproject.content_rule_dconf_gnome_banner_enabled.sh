#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_banner_enabled"
TITLE="GDM login banner must be enabled (banner-message-enable=true)"

run() {
    # GDM is required for this control
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|gdm3 is not installed (control not applicable)"
        return 0
    fi

    local db_dir="/etc/dconf/db/gdm.d"
    local locks_dir="/etc/dconf/db/gdm.d/locks"

    if [ ! -d "$db_dir" ]; then
        echo "WARN|$RULE_ID|$db_dir does not exist; GDM login banner is likely not configured"
        return 0
    fi

    # Check if banner-message-enable=true is present in GDM dconf database
    if grep -Rqs "^\s*banner-message-enable\s*=\s*true\s*$" "$db_dir"; then
        config_ok=1
    else
        config_ok=0
    fi

    # Check if the key is locked under /etc/dconf/db/gdm.d/locks
    if [ -d "$locks_dir" ] && grep -Rqs "^/org/gnome/login-screen/banner-message-enable$" "$locks_dir"; then
        lock_ok=1
    else
        lock_ok=0
    fi

    if [ "$config_ok" -eq 1 ] && [ "$lock_ok" -eq 1 ]; then
        echo "OK|$RULE_ID|GDM login banner is enabled and locked via dconf (banner-message-enable=true)"
    elif [ "$config_ok" -eq 1 ] && [ "$lock_ok" -eq 0 ]; then
        echo "WARN|$RULE_ID|banner-message-enable=true is set in $db_dir but not locked in $locks_dir"
    elif [ "$config_ok" -eq 0 ] && [ "$lock_ok" -eq 1 ]; then
        echo "WARN|$RULE_ID|banner-message-enable is locked in $locks_dir but no banner-message-enable=true found in $db_dir"
    else
        echo "WARN|$RULE_ID|GDM login banner is not properly configured (banner-message-enable=true missing in $db_dir and no lock in $locks_dir)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
