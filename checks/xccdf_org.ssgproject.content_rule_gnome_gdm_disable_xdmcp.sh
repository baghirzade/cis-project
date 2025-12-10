#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_gnome_gdm_disable_xdmcp"
TITLE="XDMCP must be disabled in GDM (Enable=false under [xdmcp])"

CONFIG_FILE="/etc/gdm3/custom.conf"

has_xdmcp_disabled() {
    # Check if [xdmcp] section exists and contains Enable=false
    awk '
        BEGIN { in_section=0; found=0 }
        /^\s*\[/ {
            # entering a new section, reset flag
            in_section=0
        }
        /^\s*\[xdmcp\]\s*$/ {
            in_section=1
        }
        in_section && /^\s*Enable\s*=\s*false\s*$/ {
            found=1
        }
        END { exit(found ? 0 : 1) }
    ' "$CONFIG_FILE"
}

run() {
    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicable only if gdm3 is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|gdm3 is not installed (control not applicable)"
        return 0
    fi

    # Config file should exist for explicit configuration
    if [ ! -f "$CONFIG_FILE" ]; then
        echo "WARN|$RULE_ID|$CONFIG_FILE does not exist (XDMCP disable not explicitly configured)"
        return 0
    fi

    if has_xdmcp_disabled; then
        echo "OK|$RULE_ID|XDMCP is disabled (Enable=false under [xdmcp] in $CONFIG_FILE)"
    else
        echo "WARN|$RULE_ID|[xdmcp] section or Enable=false is missing/misconfigured in $CONFIG_FILE"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
