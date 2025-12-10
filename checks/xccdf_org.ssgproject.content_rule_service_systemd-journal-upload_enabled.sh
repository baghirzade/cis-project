#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_systemd-journal-upload_enabled"
TITLE="systemd-journal-upload service should be enabled (and active) when systemd-journal-remote is used"

run() {
    SYSTEMCTL_EXEC="${SYSTEMCTL_EXEC:-/usr/bin/systemctl}"

    # Debian/Ubuntu requirement (dpkg)
    if ! command -v dpkg-query >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg-query not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # linux-base paketi yoxdursa -> not applicable
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed (non-standard Debian/Ubuntu environment)"
        return 0
    fi

    # Container mühiti (Docker / container env) -> not applicable
    if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
        echo "NOTAPPL|$RULE_ID|Running inside a container (systemd-journal-upload service control not applicable)"
        return 0
    fi

    # systemd-journal-remote paketi quraşdırılmayıbsa -> bu qayda tətbiq olunmur
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'systemd-journal-remote' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|systemd-journal-remote package is not installed (remote journald upload not in use)"
        return 0
    fi

    # systemd-journal-upload servisinin enabled & active olmasını yoxlayaq
    if ! command -v "$SYSTEMCTL_EXEC" >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|systemctl not found, cannot verify systemd-journal-upload state"
        return 0
    fi

    local enabled_state active_state
    enabled_state="$("$SYSTEMCTL_EXEC" is-enabled systemd-journal-upload.service 2>/dev/null || echo "unknown")"
    active_state="$("$SYSTEMCTL_EXEC" is-active systemd-journal-upload.service 2>/dev/null || echo "inactive")"

    if [[ "$enabled_state" == "enabled" && "$active_state" == "active" ]]; then
        echo "OK|$RULE_ID|systemd-journal-upload.service is enabled and active"
        return 0
    fi

    # Daha detallı xəbərdarlıq ver
    echo "WARN|$RULE_ID|systemd-journal-upload.service state is not compliant (enabled=$enabled_state, active=$active_state)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
