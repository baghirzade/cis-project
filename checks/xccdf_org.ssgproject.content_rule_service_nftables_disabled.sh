#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_nftables_disabled"
TITLE="Ensure nftables service is disabled"

run() {

    # dpkg required (Debian-based check)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found"
        return 0
    fi

    # nftables must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' nftables \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|nftables package not installed"
        return 0
    fi

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    SERVICE_STATE=$(systemctl is-enabled nftables 2>/dev/null || echo "unknown")
    ACTIVE_STATE=$(systemctl is-active nftables 2>/dev/null || echo "unknown")

    if [[ "$SERVICE_STATE" == "disabled" || "$SERVICE_STATE" == "masked" ]] \
       && [[ "$ACTIVE_STATE" == "inactive" || "$ACTIVE_STATE" == "failed" ]]; then
        echo "OK|$RULE_ID|nftables service is disabled"
    else
        echo "WARN|$RULE_ID|nftables service is NOT disabled (enabled=$SERVICE_STATE active=$ACTIVE_STATE)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
