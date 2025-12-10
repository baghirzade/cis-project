#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ip6tables_rules_for_open_ports"

echo "[*] Applying remediation for: $RULE_ID (create ip6tables rules for open IPv6 ports)"

# ip6tables required
if ! command -v ip6tables >/dev/null 2>&1; then
    echo "[!] ip6tables not available. Skipping."
    exit 0
fi

# Rule applies only if nftables/ufw NOT installed
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables installed; remediation not applicable."
    exit 0
fi

if dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw installed; remediation not applicable."
    exit 0
fi

# Detect open IPv6 ports
mapfile -t PORTS < <(ss -tlunp 'ip6' 2>/dev/null | awk 'NR>1 {print $5}' | sed 's/.*://')

if [ ${#PORTS[@]} -eq 0 ]; then
    echo "[*] No open IPv6 TCP ports present; nothing to remediate."
    exit 0
fi

echo "[*] Adding ip6tables allow rules for open ports..."

for PORT in "${PORTS[@]}"; do
    if ! ip6tables -S INPUT | grep -qE "^-A INPUT .* --dport ${PORT} .* -j ACCEPT"; then
        echo "[+] Allowing inbound IPv6 TCP port ${PORT}"
        ip6tables -A INPUT -p tcp --dport "$PORT" -j ACCEPT
    fi
done

echo "[*] Saving persistent configuration if supported..."

if command -v netfilter-persistent >/dev/null 2>&1; then
    netfilter-persistent save || true
elif command -v service >/dev/null 2>&1 && service netfilter-persistent status >/dev/null 2>&1; then
    service netfilter-persistent save || true
fi

echo "[+] Remediation complete: ip6tables rules for all open IPv6 ports created."
