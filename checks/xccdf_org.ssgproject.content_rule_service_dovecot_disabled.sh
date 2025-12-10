#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_dovecot_disabled"
TITLE="Ensure dovecot.service is disabled and masked"

run() {
    # dpkg is required for applicability check
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg unavailable (non-Debian/Ubuntu system)"
        return 0
    fi

    # linux-base must be installed for rule applicability
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed (rule not applicable)"
        return 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # If service does not exist → OK
    if ! $SYSTEMCTL -q list-unit-files dovecot.service 2>/dev/null; then
        echo "OK|$RULE_ID|dovecot.service not present"
        return 0
    fi

    # Service must be disabled
    if $SYSTEMCTL is-enabled dovecot.service 2>/dev/null | grep -vq disabled; then
        echo "FAIL|$RULE_ID|dovecot.service is not disabled"
        return 0
    fi

    # Service must be masked
    if ! $SYSTEMCTL is-enabled dovecot.service 2>/dev/null | grep -q masked; then
        echo "FAIL|$RULE_ID|dovecot.service is not masked"
        return 0
    fi

    echo "OK|$RULE_ID|dovecot.service is disabled and masked"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
