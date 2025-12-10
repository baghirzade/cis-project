#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_vsftpd_removed"

echo "[*] Applying remediation for: $RULE_ID (remove vsftpd)"

# Ensure Debian/Ubuntu environment
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable."
    exit 0
fi

# If package not installed, nothing to do
if ! dpkg -s vsftpd >/dev/null 2>&1; then
    echo "[*] Package 'vsftpd' is already absent. No action required."
    exit 0
fi

echo "[!] WARNING: This will remove 'vsftpd' and potentially dependent packages."

# Remove vsftpd
DEBIAN_FRONTEND=noninteractive apt-get remove -y vsftpd || true

echo "[+] Remediation complete: vsftpd removed (if present)."
