#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_ip6tables_default_rule"

echo "[*] Applying remediation for: $RULE_ID (set ip6tables default policies to DROP)"

# ip6tables required
if ! command -v ip6tables >/dev/null 2>&1; then
    echo "[!] ip6tables not available. Remediation cannot proceed."
    exit 0
fi

# Apply DROP default policies
echo "[*] Setting ip6tables default policies to DROP"

ip6tables -P INPUT DROP
ip6tables -P OUTPUT DROP
ip6tables -P FORWARD DROP

echo "[*] Saving ip6tables rules persistently (if iptables-persistent exists)"

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

echo "[+] Remediation complete: ip6tables default rules set to DROP."
