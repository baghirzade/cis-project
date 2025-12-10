#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_at_deny"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/at.deny"

# Ensure file exists
if [ ! -f "$FILE" ]; then
    echo "[!] $FILE does not exist — creating..."
    touch "$FILE"
fi

echo "[*] Applying correct permissions (0640) to $FILE..."
chmod u-xs,g-xws,o-xwrt "$FILE"

echo "[+] Remediation complete for $RULE_ID"
