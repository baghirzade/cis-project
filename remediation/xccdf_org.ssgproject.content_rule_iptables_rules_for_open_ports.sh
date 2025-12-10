#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_iptables_rules_for_open_ports"

echo "[*] Applying remediation for: $RULE_ID (create iptables rules for open IPv4 ports)"

# iptables required
if ! command -v iptables >/dev/null 2>&1; then
    echo "[!] iptables not available. Skipping remediation."
    exit 0
fi

# nftables disables this rule
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables installed; remediation not applicable."
    exit 0
fi

# ufw disables this rule
if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw installed; remediation not applicable."
    exit 0
fi

# Detect open IPv4 TCP ports
mapfile -t PORTS < <(ss -tlnp 2>/dev/null | awk 'NR>1 {print $4}' | sed 's/.*://')

if [ ${#PORTS[@]} -eq 0 ]; then
    echo "[*] No open IPv4 TCP ports found; nothing to remediate."
    exit 0
fi

echo "[*] Adding iptables allow rules for open IPv4 ports..."

for PORT in "${PORTS[@]}"; do
    if ! iptables -S INPUT | grep -qE "^-A INPUT .* --dport ${PORT} .* -j ACCEPT"; then
        echo "[+] Allowing inbound IPv4 TCP port ${PORT}"
        iptables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
    fi
done

# Persist rules if possible
echo "[*] Saving persistent firewall rules..."

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

echo "[+] Remediation complete: iptables rules for open IPv4 ports created."
