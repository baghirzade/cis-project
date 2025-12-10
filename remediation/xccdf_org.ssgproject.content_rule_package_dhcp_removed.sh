#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_dhcp_removed"

echo "[*] Applying remediation for: $RULE_ID (remove isc-dhcp-server)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable on this system. Skipping."
    exit 0
fi

# If package is NOT installed → nothing to do
if ! dpkg -s isc-dhcp-server >/dev/null 2>&1; then
    echo "[*] Package 'isc-dhcp-server' is already absent. No changes needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'isc-dhcp-server' and possibly dependent packages."

# Remove DHCP server package
DEBIAN_FRONTEND=noninteractive apt-get remove -y isc-dhcp-server || true

echo "[+] Remediation complete: 'isc-dhcp-server' package removed (if present)."
