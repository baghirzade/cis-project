#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_ufw_default_rule"
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
    echo "[!] ufw package not installed — skipping"
    exit 0
fi

# SCAP-selected firewall
var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")
if [[ "$var_network_filtering_service" != "ufw" ]]; then
    echo "[*] Firewall '$var_network_filtering_service' selected — UFW defaults not applicable"
    exit 0
fi

echo "[*] Setting UFW default policies:"
echo "    incoming: deny"
echo "    outgoing: allow"
echo "    routed:   deny"

ufw default deny incoming
ufw default allow outgoing
ufw default deny routed

echo "[+] Remediation complete: UFW default rules configured"
