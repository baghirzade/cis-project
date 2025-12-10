#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_autofs_removed"

echo "[*] Remediating: \$RULE_ID"
echo "[!] WARNING: This will remove 'autofs' and dependencies. Use with caution."

if dpkg -l | grep -q "^ii\s\+autofs"; then
    DEBIAN_FRONTEND=noninteractive apt-get remove -y autofs
    echo "[+] autofs package removed"
else
    echo "[*] autofs is already not installed"
fi

echo "[+] Remediation completed for: \$RULE_ID"
