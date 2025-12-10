#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_ftp_removed"

echo "[*] Applying remediation for: $RULE_ID (remove ftp package)"

# Ensure dpkg environment available
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable on this system."
    exit 0
fi

# If ftp package is not installed, nothing to do
if ! dpkg -s ftp >/dev/null 2>&1; then
    echo "[*] Package 'ftp' is already absent. No action required."
    exit 0
fi

echo "[!] WARNING: This action will remove 'ftp' and potentially dependent packages."

# Remove ftp package
DEBIAN_FRONTEND=noninteractive apt-get remove -y ftp || true

echo "[+] Remediation complete: ftp removed (if installed)."
