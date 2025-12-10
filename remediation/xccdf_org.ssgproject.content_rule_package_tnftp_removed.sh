#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_tnftp_removed"

echo "[*] Applying remediation for: $RULE_ID (remove tnftp)"

# Ensure dpkg platform
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable."
    exit 0
fi

# If tnftp is not installed → nothing to remove
if ! dpkg -s tnftp >/dev/null 2>&1; then
    echo "[*] Package 'tnftp' is already absent. No action required."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'tnftp' and may remove packages depending on it."

# Remove tnftp
DEBIAN_FRONTEND=noninteractive apt-get remove -y tnftp || true

echo "[+] Remediation complete: tnftp removed (if present)."
