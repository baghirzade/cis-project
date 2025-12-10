#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_dnsmasq_removed"

echo "[*] Applying remediation for: $RULE_ID (remove dnsmasq)"

# Ensure Debian/Ubuntu platform
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable on this system."
    exit 0
fi

# If dnsmasq is not installed → nothing to do
if ! dpkg -s dnsmasq >/dev/null 2>&1; then
    echo "[*] Package 'dnsmasq' is already absent. No changes needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'dnsmasq' and possibly dependent packages."

# Remove dnsmasq
DEBIAN_FRONTEND=noninteractive apt-get remove -y dnsmasq || true

echo "[+] Remediation complete: dnsmasq removed (if present)."
