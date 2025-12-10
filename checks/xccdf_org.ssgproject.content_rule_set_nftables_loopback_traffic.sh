#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_nftables_loopback_traffic"

run() {

    # nftables installed?
    if ! command -v nft &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|nftables not installed"
        return 0
    fi

    # firewalld should NOT be active
    if systemctl is-active firewalld &>/dev/null; then
        echo "NOTAPPL|$RULE_ID|firewalld active — nftables rules skipped"
        return 0
    fi

    RS=$(nft list ruleset)

    # Check loopback input accept rule
    if ! echo "$RS" | grep -q 'iif "lo" accept'; then
        echo "WARN|$RULE_ID|Missing: accept traffic on loopback interface"
        return 0
    fi

    # Check IPv4 loopback drop rule
    if ! echo "$RS" | grep -q 'ip saddr 127.0.0.0/8 .* drop'; then
        echo "WARN|$RULE_ID|Missing: drop non-loopback IPv4 traffic on 127.0.0.0/8"
        return 0
    fi

    # IPv6 enabled?
    IPV6_DISABLED=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)

    if [[ "$IPV6_DISABLED" -eq 0 ]]; then
        if ! echo "$RS" | grep -q 'ip6 saddr ::1 .* drop'; then
            echo "WARN|$RULE_ID|Missing IPv6 loopback drop rule"
            return 0
        fi
    fi

    echo "OK|$RULE_ID|Loopback nftables rules properly configured"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
