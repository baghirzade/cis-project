#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_openldap-clients_removed"

echo "[*] Applying remediation for: $RULE_ID (remove ldap-utils)"

# Ensure dpkg exists (Debian/Ubuntu systems)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable."
    exit 0
fi

# If ldap-utils not installed → nothing to do
if ! dpkg -s ldap-utils >/dev/null 2>&1; then
    echo "[*] Package 'ldap-utils' already absent. No action needed."
    exit 0
fi

echo "[!] WARNING: This remediation will remove 'ldap-utils' and may also remove dependent packages."

# Remove ldap-utils
DEBIAN_FRONTEND=noninteractive apt-get remove -y ldap-utils || true

echo "[+] Remediation complete: ldap-utils removed (if present)."
