#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_default_accept_redirects"
TITLE="Ensure IPv4 ICMP redirects are not accepted by default"

run() {
    # Check platform applicability (e.g., Debian/Ubuntu)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi
    
    SYSCTL_KEY="net.ipv4.conf.default.accept_redirects"
    EXPECTED_VALUE="0"
    CONFIG_FILES="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"
    
    # 1. Check current running value
    CURRENT_RUNTIME_VALUE=$(sysctl -n "$SYSCTL_KEY" 2>/dev/null || true)
    
    if [ "$CURRENT_RUNTIME_VALUE" != "$EXPECTED_VALUE" ]; then
        echo "WARN|$RULE_ID|Runtime value is $CURRENT_RUNTIME_VALUE, expected $EXPECTED_VALUE."
        return 1
    fi

    # 2. Check persistent configuration files
    CONFIGURED_VALUE=$(grep -P -r -i "^\s*$SYSCTL_KEY\s*=\s*\d+" $CONFIG_FILES 2>/dev/null | grep -P -v '^\s*#' | tail -n 1 | awk -F'=' '{print $2}' | tr -d '[:space:]')
    
    # Check if the persistently configured value matches the expected value
    if [ -z "$CONFIGURED_VALUE" ] || [ "$CONFIGURED_VALUE" == "$EXPECTED_VALUE" ]; then
        echo "OK|$RULE_ID|Runtime and persistent configuration values are both $EXPECTED_VALUE (or not explicitly overridden)."
        return 0
    else
        echo "WARN|$RULE_ID|Persistent configuration found: $SYSCTL_KEY=$CONFIGURED_VALUE, expected $EXPECTED_VALUE."
        return 1
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
