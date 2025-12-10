#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_default_rp_filter"
TITLE="Ensure net.ipv4.conf.default.rp_filter is set to 1"

run() {
    # Debian-based check
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found"
        return 0
    fi

    # linux-base required
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # Runtime sysctl value
    RUNTIME=$(sysctl -n net.ipv4.conf.default.rp_filter 2>/dev/null)
    if [ "$RUNTIME" != "1" ]; then
        echo "WARN|$RULE_ID|Runtime value is $RUNTIME (expected 1)"
        return 0
    fi

    BAD=0
    SEARCH_PATHS="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    # Persistent config check
    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv4\.conf\.default\.rp_filter\s*=\s*0'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv4.conf.default.rp_filter" $SEARCH_PATHS 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|Non-compliant persistent settings found"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv4.conf.default.rp_filter is correctly set to 1"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
