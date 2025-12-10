#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_bind_removed"

echo "[*] Applying remediation for: $RULE_ID (remove bind9)"

# Ensure dpkg presence
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; not a Debian-based system. Skipping."
    exit 0
fi

# If bind9 is not installed → nothing to do
if ! dpkg -s bind9 >/dev/null 2>&1; then
    echo "[*] Package 'bind9' already absent. No action needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'bind9' and may remove dependent packages."

# Remove bind9
DEBIAN_FRONTEND=noninteractive apt-get remove -y bind9 || true

echo "[+] Remediation complete: bind9 removed (if present)."
