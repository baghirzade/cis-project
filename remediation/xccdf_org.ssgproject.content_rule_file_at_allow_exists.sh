#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_at_allow_exists"
echo "[*] Remediating: $RULE_ID"

# Applicability check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/at.allow"

echo "[*] Ensuring $FILE exists..."
touch "$FILE"

echo "[*] Setting correct owner..."
chown 0 "$FILE"

echo "[*] Setting correct permissions..."
chmod 0640 "$FILE"

echo "[+] Remediation complete for $RULE_ID"
