#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_ufw_installed"
echo "[*] Remediating: $RULE_ID"

# linux-base lazımdır
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed — skipping"
    exit 0
fi

# Selected firewall service (same variable as SCAP uses)
var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")

# Default (CIS standard) → ufw seçilibsə, quraşdırılmalıdır
if [[ "$var_network_filtering_service" == "ufw" ]]; then
    echo "[*] Installing ufw firewall package..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y ufw
else
    echo "[*] Firewall service is '$var_network_filtering_service' — UFW not required"
fi

echo "[+] Remediation complete"
