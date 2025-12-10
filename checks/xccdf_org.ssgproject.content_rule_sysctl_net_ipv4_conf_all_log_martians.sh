#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv4_conf_all_log_martians"
TITLE="Ensure net.ipv4.conf.all.log_martians is set to 1"

run() {
    # dpkg required
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not installed"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
        | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base missing"
        return 0
    fi

    # runtime value check
    RUNTIME=$(sysctl -n net.ipv4.conf.all.log_martians 2>/dev/null)
    if [ "$RUNTIME" != "1" ]; then
        echo "WARN|$RULE_ID|Runtime value is $RUNTIME (expected 1)"
        return 0
    fi

    BAD=0
    FILES="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    # persistent config scan
    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv4\.conf\.all\.log_martians\s*=\s*0'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv4.conf.all.log_martians" $FILES 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|Non-compliant persistent config detected"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv4.conf.all.log_martians is correctly set to 1"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
