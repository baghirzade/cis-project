#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_sysctl_net_ipv6_conf_all_accept_ra"
TITLE="Ensure net.ipv6.conf.all.accept_ra is set to 0"

run() {
    # Debian-based required
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available"
        return 0
    fi

    # linux-base must be installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|linux-base is not installed"
        return 0
    fi

    # Runtime value
    RUNTIME_VALUE=$(sysctl -n net.ipv6.conf.all.accept_ra 2>/dev/null)
    if [ "$RUNTIME_VALUE" != "0" ]; then
        echo "WARN|$RULE_ID|Runtime value is $RUNTIME_VALUE, expected 0"
        return 0
    fi

    # Check sysctl configuration files
    BAD=0
    SEARCH_PATHS="/etc/sysctl.conf /etc/sysctl.d/*.conf /run/sysctl.d/*.conf /usr/local/lib/sysctl.d/*.conf /etc/ufw/sysctl.conf"

    while IFS= read -r line; do
        if echo "$line" | grep -Eq '^\s*net\.ipv6\.conf\.all\.accept_ra\s*=\s*[1-9]'; then
            BAD=1
        fi
    done < <(grep -R "net.ipv6.conf.all.accept_ra" $SEARCH_PATHS 2>/dev/null || true)

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|One or more sysctl files contain non-compliant accept_ra settings"
        return 0
    fi

    echo "OK|$RULE_ID|net.ipv6.conf.all.accept_ra is correctly set to 0 (runtime and config)"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
