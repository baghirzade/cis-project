#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_dovecot_removed"

echo "[*] Applying remediation for: $RULE_ID (remove dovecot-core)"

# Ensure dpkg exists (Debian-based OS)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable."
    exit 0
fi

# If dovecot-core is already not installed → skip
if ! dpkg -s dovecot-core >/dev/null 2>&1; then
    echo "[*] Package 'dovecot-core' already absent. No changes required."
    exit 0
fi

echo "[!] WARNING: This remediation removes 'dovecot-core' and may remove dependent packages."

# Remove package
DEBIAN_FRONTEND=noninteractive apt-get remove -y dovecot-core || true

echo "[+] Remediation complete: dovecot-core removed (if installed)."
