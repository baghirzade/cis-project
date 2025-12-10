#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_iptables-persistent_removed"

echo "[*] Applying remediation for: $RULE_ID (remove iptables-persistent when ufw is installed)"

# Ensure dpkg exists (Debian/Ubuntu only)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found. Remediation not applicable."
    exit 0
fi

# Remediation applies only if ufw is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'ufw' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] ufw is not installed. Remediation not applicable."
    exit 0
fi

# Remove iptables-persistent if present
if dpkg-query --show --showformat='${db:Status-Status}' 'iptables-persistent' 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Removing iptables-persistent (CAUTION: may remove dependent packages)"
    DEBIAN_FRONTEND=noninteractive apt-get remove -y "iptables-persistent"
else
    echo "[*] iptables-persistent is already absent. Nothing to remove."
fi

echo "[+] Remediation complete: iptables-persistent removed."
