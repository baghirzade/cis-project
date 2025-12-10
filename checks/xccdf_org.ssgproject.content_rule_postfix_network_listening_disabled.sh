#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_postfix_network_listening_disabled"
TITLE="Ensure Postfix listens only on loopback (inet_interfaces=loopback-only)"

run() {
    # Check applicability
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Not a Debian-based system"
        return 0
    fi

    if ! dpkg -s postfix >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Postfix not installed"
        return 0
    fi

    CFG="/etc/postfix/main.cf"

    if [[ ! -f "$CFG" ]]; then
        echo "WARN|$RULE_ID|main.cf missing"
        return 0
    fi

    # Extract inet_interfaces
    VALUE=$(grep -E '^\s*inet_interfaces\s*=' "$CFG" | awk -F= '{print $2}' | tr -d " ")

    if [[ "$VALUE" == "loopback-only" ]]; then
        echo "OK|$RULE_ID|inet_interfaces correctly set to loopback-only"
    else
        echo "WARN|$RULE_ID|inet_interfaces is '$VALUE' (expected loopback-only)"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
