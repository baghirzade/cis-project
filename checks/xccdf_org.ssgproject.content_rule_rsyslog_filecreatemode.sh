#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_rsyslog_filecreatemode"
TITLE="rsyslog must create log files with mode 0640 via \$FileCreateMode"

run() {
    # dpkg: only Debian/Ubuntu
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Applicable only if linux-base is installed (per SCAP logic)
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package is not installed (control not applicable)"
        return 0
    fi

    # rsyslog service must be active
    if ! command -v systemctl >/dev/null 2>&1; then
        echo "WARN|$RULE_ID|systemctl not available; cannot determine rsyslog status"
        return 0
    fi

    if ! systemctl is-active rsyslog >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|rsyslog service is not active (control not applicable)"
        return 0
    fi

    RSYSLOG_CONF="/etc/rsyslog.conf"
    RSYSLOG_D="/etc/rsyslog.d"

    if [ ! -f "$RSYSLOG_CONF" ] && [ ! -d "$RSYSLOG_D" ]; then
        echo "WARN|$RULE_ID|Neither $RSYSLOG_CONF nor $RSYSLOG_D exists; rsyslog configuration not found"
        return 0
    fi

    SEARCH_PATHS=()
    [ -f "$RSYSLOG_CONF" ] && SEARCH_PATHS+=("$RSYSLOG_CONF")
    [ -d "$RSYSLOG_D" ] && SEARCH_PATHS+=("$RSYSLOG_D")

    # Collect non-commented $FileCreateMode lines
    mapfile -t FILECREATE_LINES < <(
        grep -R -E '^[[:space:]]*\$FileCreateMode[[:space:]]+[0-9]{4}' "${SEARCH_PATHS[@]}" 2>/dev/null \
        | grep -v '^[[:space:]]*#'
    )

    if [ "${#FILECREATE_LINES[@]}" -eq 0 ]; then
        echo "WARN|$RULE_ID|\$FileCreateMode is not configured (no non-commented directives found in rsyslog configuration)"
        return 0
    fi

    # Any directive not equal to 0640 is a finding
    mapfile -t BAD_LINES < <(
        printf '%s\n' "${FILECREATE_LINES[@]}" \
        | awk '!/\$FileCreateMode[[:space:]]+0640([[:space:]]|$)/'
    )

    if [ "${#BAD_LINES[@]}" -ne 0 ]; then
        echo "WARN|$RULE_ID|Found \$FileCreateMode directives not set to 0640 (${#BAD_LINES[@]} occurrence(s))"
        return 0
    fi

    echo "OK|$RULE_ID|\$FileCreateMode is set to 0640 for rsyslog log file creation (no conflicting directives found)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
