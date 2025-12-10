#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_nis_removed"

echo "[*] Applying remediation for: $RULE_ID (remove NIS package)"

# Ensure Debian-based system
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable on this system. Skipping."
    exit 0
fi

# If package is NOT installed → nothing to do
if ! dpkg -s nis >/dev/null 2>&1; then
    echo "[*] Package 'nis' is already absent. No changes needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'nis' and potentially dependent packages."

# Remove NIS package
DEBIAN_FRONTEND=noninteractive apt-get remove -y nis || true

echo "[+] Remediation complete: 'nis' package removed (if present)."
