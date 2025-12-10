#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_all_secure_redirects"
TITLE="Ensure net.ipv4.conf.all.secure_redirects is set to 0"

run() {
    # dpkg required (Debian/Ubuntu only)
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base package missing"
        return 0
    fi

    # Runtime sysctl value
    RUNTIME=$(sysctl -n net.ipv4.conf.all.secure_redirects 2>/dev/null)
    if [ "$RUNTIME" != "0" ]; then
        echo "WARN|$RULE_ID|Runtime value is $RUNTIME (expected 0)"
        return 0
    fi

    # Persistent configuration validation
    BAD=0
    FILES="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv4\.conf\.all\.secure_redirects\s*=\s*[1-9]'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv4.conf.all.secure_redirects" $FILES 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|Non-compliant secure_redirects entries detected in sysctl configs"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv4.conf.all.secure_redirects is correctly set to 0"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
