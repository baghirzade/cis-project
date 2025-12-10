#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_tcp_syncookies"
TITLE="Ensure net.ipv4.tcp_syncookies is set to 1"

run() {
    # Applicable only for Debian/Ubuntu with dpkg
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not detected"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
        2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base missing"
        return 0
    fi

    # Check runtime value
    RUNTIME=$(sysctl -n net.ipv4.tcp_syncookies 2>/dev/null)
    if [ "$RUNTIME" != "1" ]; then
        echo "WARN|$RULE_ID|Runtime value $RUNTIME (expected 1)"
        return 0
    fi

    BAD=0
    SEARCH="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf \
/usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    # Scan persistent configuration
    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv4\.tcp_syncookies\s*=\s*0'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv4.tcp_syncookies" $SEARCH 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|Non-compliant persistent config found"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv4.tcp_syncookies correctly set to 1"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
