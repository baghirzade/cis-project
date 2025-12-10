#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_apport_disabled"

run() {

    # If apport is not installed → rule is not applicable
    if ! dpkg-query --show --showformat='${db:Status-Status}' apport 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|apport not installed (rule N/A)"
        exit 0
    fi

    SYSTEMCTL="/usr/bin/systemctl"

    # Check enabled/disabled
    if "$SYSTEMCTL" is-enabled apport.service 2>/dev/null | grep -vq "disabled"; then
        echo "WARN|$RULE_ID|apport.service is enabled"
        exit 1
    fi

    # Check masked
    if ! "$SYSTEMCTL" is-enabled apport.service 2>/dev/null | grep -q "masked"; then
        echo "WARN|$RULE_ID|apport.service is not masked"
        exit 1
    fi

    # Check service inactive
    if "$SYSTEMCTL" is-active apport.service 2>/dev/null | grep -vq "inactive"; then
        echo "WARN|$RULE_ID|apport.service is active"
        exit 1
    fi

    echo "OK|$RULE_ID|apport service disabled and masked"
    exit 0
}

run
