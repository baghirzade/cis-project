#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_ipv6_loopback_traffic"

echo "[*] Applying remediation for: $RULE_ID (configure IPv6 loopback rules)"

# Rule applies only if iptables is installed AND nftables/ufw are NOT installed
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables installed; remediation not applicable."
    exit 0
fi

if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw installed; remediation not applicable."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] iptables not installed; remediation cannot proceed."
    exit 0
fi

# Skip if IPv6 disabled
if [ "$(sysctl -n net.ipv6.conf.all.disable_ipv6)" -eq 1 ]; then
    echo "[!] IPv6 disabled; remediation not needed."
    exit 0
fi

echo "[*] Applying IPv6 loopback traffic rules..."

# Accept loopback traffic
ip6tables -A INPUT -i lo -j ACCEPT || true
ip6tables -A OUTPUT -o lo -j ACCEPT || true

# Drop traffic claiming to come from ::1 externally
ip6tables -A INPUT -s ::1 -j DROP || true

echo "[+] IPv6 loopback traffic rules applied successfully."

# Persist if possible
if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

