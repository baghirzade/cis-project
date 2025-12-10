#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_ufw_enabled"
echo "[*] Applying remediation for: $RULE_ID"

# linux-base lazımdır
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed — skipping"
    exit 0
fi

# UFW quraşdırılmayıbsa
if ! dpkg-query --show --showformat='${db:Status-Status}' ufw \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw package not installed — skipping"
    exit 0
fi

# SCAP variable for selected firewall service
var_network_filtering_service=$(grep -E '^var_network_filtering_service=' /etc/default/firewall 2>/dev/null | cut -d= -f2 || echo "ufw")

SYSTEMCTL_EXEC='/usr/bin/systemctl'

# CIS logic: only enable UFW when it is the selected firewall
if [[ "$var_network_filtering_service" == "ufw" ]]; then
    echo "[*] Enabling and starting ufw.service"

    "$SYSTEMCTL_EXEC" unmask ufw.service || true
    "$SYSTEMCTL_EXEC" enable ufw.service
    "$SYSTEMCTL_EXEC" start ufw.service

    echo "[+] Remediation complete: ufw service enabled and active"
else
    echo "[*] Selected firewall is '$var_network_filtering_service'. UFW enable not required."
fi

