#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_forwarding"
TITLE="Ensure net.ipv6.conf.all.forwarding is set to 0"

run() {
    # Debian platform check
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available"
        return 0
    fi

    # linux-base must exist
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # Check runtime sysctl value
    RUNTIME_VAL=$(sysctl -n net.ipv6.conf.all.forwarding 2>/dev/null)
    if [ "$RUNTIME_VAL" != "0" ]; then
        echo "WARN|$RULE_ID|Runtime value is $RUNTIME_VAL (expected 0)"
        return 0
    fi

    BAD=0
    SEARCH="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    # Scan configuration files for incorrect values
    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv6\.conf\.all\.forwarding\s*=\s*[1-9]'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv6.conf.all.forwarding" $SEARCH 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|Non-compliant values detected in persistent configs"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv6.conf.all.forwarding is correctly set to 0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
