#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_loopback_traffic"

echo "[*] Applying remediation for: $RULE_ID (configure IPv4 loopback firewall rules)"

# Rule applies only if iptables installed AND nftables/ufw NOT installed
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables installed; remediation not applicable."
    exit 0
fi

if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw installed; remediation not applicable."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' 'iptables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] iptables is not installed; remediation cannot proceed."
    exit 0
fi

echo "[*] Applying IPv4 loopback configuration..."

# Accept loopback traffic
iptables -A INPUT -i lo -j ACCEPT || true
iptables -A OUTPUT -o lo -j ACCEPT || true

# Drop external packets claiming to come from 127.0.0.0/8
iptables -A INPUT -s 127.0.0.0/8 -j DROP || true

echo "[+] IPv4 loopback traffic rules applied successfully."

# Persist if possible
if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

