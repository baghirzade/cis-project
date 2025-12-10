#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_check_ufw_active"
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

# SCAP firewall selection
var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")

SYSTEMCTL_EXEC='/usr/bin/systemctl'

if [[ "$var_network_filtering_service" == "ufw" ]]; then

    echo "[*] Ensuring ufw service is running"
    "$SYSTEMCTL_EXEC" unmask ufw.service || true
    "$SYSTEMCTL_EXEC" start ufw.service || true
    "$SYSTEMCTL_EXEC" enable ufw.service || true

    echo "[*] Enabling ufw firewall ruleset"
    ufw --force enable

    echo "[+] Remediation complete: ufw is active"

else
    echo "[*] Firewall selection is '$var_network_filtering_service'. UFW activation not required."
fi

