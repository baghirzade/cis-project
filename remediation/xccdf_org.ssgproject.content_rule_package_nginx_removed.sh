#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_nginx_removed"

echo "[*] Applying remediation for: $RULE_ID (remove nginx)"

# Ensure Debian-based platform
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; remediation not applicable."
    exit 0
fi

# If nginx not installed → nothing to do
if ! dpkg -s nginx >/dev/null 2>&1; then
    echo "[*] nginx package already absent. No action needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'nginx' and may remove dependent packages."

# Remove nginx package
DEBIAN_FRONTEND=noninteractive apt-get remove -y nginx || true

echo "[+] Remediation complete: nginx removed (if present)."
