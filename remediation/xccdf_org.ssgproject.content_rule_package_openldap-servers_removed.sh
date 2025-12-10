#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_openldap-servers_removed"

echo "[*] Applying remediation for: $RULE_ID (remove slapd)"

# dpkg required
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; remediation not applicable."
    exit 0
fi

# If slapd is not installed → nothing to remove
if ! dpkg -s slapd >/dev/null 2>&1; then
    echo "[*] Package 'slapd' already absent. No changes required."
    exit 0
fi

echo "[!] WARNING: Removing 'slapd' may also remove dependent LDAP server packages."

# Remove slapd package
DEBIAN_FRONTEND=noninteractive apt-get remove -y slapd || true

echo "[+] Remediation complete: slapd removed (if installed)."
