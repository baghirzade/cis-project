#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_nftables_loopback_traffic"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure nftables is installed and firewalld inactive
if ! dpkg-query --show --showformat='${db:Status-Status}' nftables \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables not installed — skipping"
    exit 0
fi

if systemctl is-active firewalld &>/dev/null; then
    echo "[!] firewalld active — skipping nftables remediation"
    exit 0
fi

FAMILY="inet"
RULEFILE="/etc/${FAMILY}-filter.rules"

echo "[*] Configuring nftables loopback rules..."

# Ensure table and chains exist
nft add table inet filter 2>/dev/null || true
nft add chain inet filter input   { type filter hook input priority 0\; }   2>/dev/null || true
nft add chain inet filter output  { type filter hook output priority 0\; }  2>/dev/null || true

# Add loopback rules (idempotent)
nft add rule inet filter input iif lo accept 2>/dev/null || true
nft add rule inet filter output oif lo accept 2>/dev/null || true

# Drop IPv4 non-loopback traffic on loopback network
nft add rule inet filter input ip saddr 127.0.0.0/8 drop 2>/dev/null || true

# Check IPv6 status
IPV6_DISABLED=$(sysctl -n net.ipv6.conf.all.disable_ipv6 2>/dev/null)

if [[ "$IPV6_DISABLED" -eq 0 ]]; then
    nft add rule inet filter input ip6 saddr ::1 drop 2>/dev/null || true
fi

echo "[*] Saving nftables rules to $RULEFILE"
nft list ruleset > "$RULEFILE"

# Update nftables.conf include line
MASTER="/etc/nftables.conf"
INCLUDE="include \"/etc/${FAMILY}-filter.rules\""

if ! grep -qxF "$INCLUDE" "$MASTER" 2>/dev/null; then
    echo "$INCLUDE" >> "$MASTER"
fi

echo "[+] Remediation complete: loopback nftables rules applied"
