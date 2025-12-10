#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_autofs_disabled"

run() {

    # autofs xidmətinin aktiv olub olmadığını yoxla
    if systemctl is-enabled autofs.service 2>/dev/null | grep -q 'enabled'; then
        echo "WARN|$RULE_ID|autofs service is enabled"
        exit 1
    fi

    if systemctl is-active autofs.service 2>/dev/null | grep -q 'active'; then
        echo "WARN|$RULE_ID|autofs service is running"
        exit 1
    fi

    echo "OK|$RULE_ID|autofs service is disabled"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
