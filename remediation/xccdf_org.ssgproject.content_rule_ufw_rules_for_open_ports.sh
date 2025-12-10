#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ufw_rules_for_open_ports"
echo "[*] Applying remediation for: $RULE_ID"

# linux-base required
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed — skipping"
    exit 0
fi

# ufw must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw not installed — skipping"
    exit 0
fi

# selected firewall must be ufw
var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")
if [[ "$var_network_filtering_service" != "ufw" ]]; then
    echo "[*] Firewall is '$var_network_filtering_service' — skipping UFW rule configuration"
    exit 0
fi

# Get open TCP ports
open_ports=$(ss -tln | awk 'NR>1 {print $4}' | sed 's/.*://')

echo "[*] Checking open ports..."
for port in $open_ports; do
    [[ -z "$port" ]] && continue

    if ! ufw status numbered | grep -q "ALLOW IN .* $port"; then
        echo "[*] Adding missing UFW allow rule for port $port"
        ufw allow "$port"/tcp
    fi
done

echo "[+] Remediation complete: UFW rules added for all open ports"
