#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_nftables_installed"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure platform requirement
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed — remediation not applicable"
    exit 0
fi

# Detect active firewall services
IPT_ACTIVE=0
UFW_ACTIVE=0

systemctl is-active iptables &>/dev/null && IPT_ACTIVE=1
systemctl is-active ufw &>/dev/null && UFW_ACTIVE=1

# nftables installation is only required if no other firewall is active
if [[ $IPT_ACTIVE -eq 0 && $UFW_ACTIVE -eq 0 ]]; then

    echo "[*] No active firewall detected — ensuring nftables is installed..."

    if dpkg-query --show --showformat='${db:Status-Status}' nftables \
        2>/dev/null | grep -q '^installed$'; then
        echo "[+] nftables is already installed"
    else
        echo "[*] Installing nftables package..."
        DEBIAN_FRONTEND=noninteractive apt-get install -y nftables
        echo "[+] nftables installation completed"
    fi

else
    echo "[!] Another firewall (iptables or ufw) is active — nftables installation not required"
fi

