#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_nfs-kernel-server_removed"

echo "[*] Applying remediation for: $RULE_ID (remove nfs-kernel-server)"

# Must be Debian-based (dpkg must exist)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation not applicable."
    exit 0
fi

# Skip if the package is not installed
if ! dpkg -s nfs-kernel-server >/dev/null 2>&1; then
    echo "[*] Package 'nfs-kernel-server' already absent. Nothing to do."
    exit 0
fi

echo "[!] WARNING: Removing 'nfs-kernel-server' may remove NFS server functionality and dependent packages."

# Remove the package
DEBIAN_FRONTEND=noninteractive apt-get remove -y nfs-kernel-server || true

echo "[+] Remediation complete: nfs-kernel-server removed (if present)."
