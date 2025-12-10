#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_iptables_default_rule"

echo "[*] Applying remediation for: $RULE_ID (set iptables default policies to DROP)"

# iptables must exist
if ! command -v iptables >/dev/null 2>&1; then
    echo "[!] iptables not found; remediation cannot continue."
    exit 0
fi

# nftables or ufw installed → rule not applicable
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables installed; iptables rules not applicable."
    exit 0
fi

if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw installed; iptables rules not applicable."
    exit 0
fi

echo "[*] Setting iptables default policies to DROP..."

iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP

echo "[*] Attempting to persist firewall configuration..."

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

echo "[+] Remediation complete: iptables default policies set to DROP."
