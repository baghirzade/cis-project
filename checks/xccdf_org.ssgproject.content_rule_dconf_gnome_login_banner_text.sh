#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_dconf_gnome_login_banner_text"
TITLE="GDM login banner must contain the CIS-required warning text"

run() {
    # Applicability: only if gdm3 is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|gdm3 is not installed (control not applicable)"
        return 0
    fi

    local expected_regex="Authorized.*users.*only.*All.*activity.*may.*be.*monitored.*and.*reported\."
    local greeter_file="/etc/gdm3/greeter.dconf-defaults"
    local dconf_dir="/etc/dconf/db/gdm.d"

    local greeter_has_banner=0
    local dconf_has_banner=0
    local greeter_has_any=0
    local dconf_has_any=0

    # ---- Check greeter.dconf-defaults ----
    if [ -f "$greeter_file" ]; then
        if grep -Eq "^\s*banner-message-text\s*=" "$greeter_file"; then
            greeter_has_any=1
            if grep -E "^\s*banner-message-text\s*=" "$greeter_file" | grep -Eq "$expected_regex"; then
                greeter_has_banner=1
            fi
        fi
    fi

    # ---- Check /etc/dconf/db/gdm.d ----
    if [ -d "$dconf_dir" ]; then
        if grep -Rqs "^\s*banner-message-text\s*=" "$dconf_dir"; then
            dconf_has_any=1
            if grep -R "^\s*banner-message-text\s*=" "$dconf_dir" | grep -Eq "$expected_regex"; then
                dconf_has_banner=1
            fi
        fi
    fi

    if [ "$greeter_has_banner" -eq 1 ] && [ "$dconf_has_banner" -eq 1 ]; then
        echo "OK|$RULE_ID|GDM login banner text matches CIS warning in both greeter.dconf-defaults and /etc/dconf/db/gdm.d"
    elif [ "$greeter_has_banner" -eq 1 ] || [ "$dconf_has_banner" -eq 1 ]; then
        echo "WARN|$RULE_ID|CIS banner text is present only in one location (greeter.dconf-defaults or /etc/dconf/db/gdm.d)"
    elif [ "$greeter_has_any" -eq 1 ] || [ "$dconf_has_any" -eq 1 ]; then
        echo "WARN|$RULE_ID|banner-message-text is configured but does not match the required CIS text"
    else
        echo "WARN|$RULE_ID|GDM login banner text is not configured with the required CIS warning"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
