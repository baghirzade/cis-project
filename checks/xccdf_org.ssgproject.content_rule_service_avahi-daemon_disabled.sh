#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_avahi-daemon_disabled"

run() {

    # Check if avahi-daemon is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' avahi-daemon 2>/dev/null | grep -q '^installed$'; then
        echo "OK|$RULE_ID|avahi-daemon package not installed, service cannot run"
        exit 0
    fi

    # Check service disabled & masked
    if systemctl is-enabled avahi-daemon.service 2>/dev/null | grep -q "disabled" &&
       systemctl is-active avahi-daemon.service 2>/dev/null | grep -q "inactive" &&
       systemctl is-enabled avahi-daemon.service 2>/dev/null | grep -q "masked"; then

        echo "OK|$RULE_ID|avahi-daemon service disabled and masked"
        exit 0
    fi

    echo "FAIL|$RULE_ID|avahi-daemon service is not properly disabled/masked"
    exit 1
}

run
