#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_httpd_removed"

echo "[*] Applying remediation for: $RULE_ID (remove apache2)"

# Ensure dpkg platform
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; not a Debian-based system. Skipping."
    exit 0
fi

# If package not installed → nothing to remove
if ! dpkg -s apache2 >/dev/null 2>&1; then
    echo "[*] Package 'apache2' is already absent. No action required."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'apache2' and may remove dependent packages."

# Remove apache2 package
DEBIAN_FRONTEND=noninteractive apt-get remove -y apache2 || true

echo "[+] Remediation complete: apache2 removed (if installed)."
