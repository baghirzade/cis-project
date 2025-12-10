#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_rpcbind_removed"

echo "[*] Applying remediation for: $RULE_ID (remove rpcbind)"

# dpkg must exist → Debian-based system
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not available; skipping remediation."
    exit 0
fi

# Rule applies only if linux-base installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
   | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

# If rpcbind not installed → nothing to do
if ! dpkg -s rpcbind >/dev/null 2>&1; then
    echo "[*] Package 'rpcbind' already absent. No action required."
    exit 0
fi

echo "[!] WARNING: Removing 'rpcbind' may remove NFS-related components."

# Remove rpcbind
DEBIAN_FRONTEND=noninteractive apt-get remove -y rpcbind || true

echo "[+] Remediation complete: rpcbind removed (if present)."
