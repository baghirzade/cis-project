#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_journald_storage"
TITLE="systemd-journald must use persistent storage when rsyslog is not active"

run() {
    local CONF="/etc/systemd/journald.conf"

    # Only Debian/Ubuntu (dpkg presence)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # linux-base paketi yoxdursa, SCAP loqikasına görə applicable deyil
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (control not applicable)"
        return 0
    fi

    # Bu qayda yalnız rsyslog aktiv DEYİLKƏN tətbiq olunur
    if systemctl is-active rsyslog &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is active (journald-only storage requirement not applicable)"
        return 0
    fi

    # Konfiqurasiya faylı mövcud olmalıdır
    if [ ! -f "$CONF" ]; then
        echo "WARN|$RULE_ID|$CONF does not exist; Storage=persistent is not explicitly configured"
        return 0
    fi

    # Storage= sətri ümumiyyətlə var?
    if ! grep -Eq '^[[:space:]]*Storage[[:space:]]*=' "$CONF"; then
        echo "WARN|$RULE_ID|Storage= is not set in $CONF (default may not be persistent)"
        return 0
    fi

    # Storage=persistent dəqiq yazılıb?
    if grep -Eq '^[[:space:]]*Storage[[:space:]]*=[[:space:]]*persistent[[:space:]]*$' "$CONF"; then
        echo "OK|$RULE_ID|Storage=persistent is configured in $CONF and rsyslog is inactive"
        return 0
    else
        local current
        current="$(grep -E '^[[:space:]]*Storage[[:space:]]*=' "$CONF" | head -n1 | sed 's/^[[:space:]]*Storage[[:space:]]*=[[:space:]]*//')"
        echo "WARN|$RULE_ID|Storage is set to '$current' (expected 'persistent') in $CONF"
        return 0
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
