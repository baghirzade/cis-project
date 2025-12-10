#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_slapd_disabled"
TITLE="Ensure slapd.service is disabled and masked"

run() {
    # dpkg required for applicability
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg unavailable (non-Debian/Ubuntu system)"
        return 0
    fi

    # linux-base required for applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed (rule not applicable)"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # If service unit not present → OK
    if ! $SYSTEMCTL -q list-unit-files slapd.service 2>/dev/null; then
        echo "OK|$RULE_ID|slapd.service not present on system"
        return 0
    fi

    # Must be disabled
    if $SYSTEMCTL is-enabled slapd.service 2>/dev/null | grep -vq disabled; then
        echo "FAIL|$RULE_ID|slapd.service is not disabled"
        return 0
    fi

    # Must be masked
    if ! $SYSTEMCTL is-enabled slapd.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|slapd.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|slapd.service is disabled and masked"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
