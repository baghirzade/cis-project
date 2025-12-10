#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_at_deny"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/at.deny"

if [ ! -f "$FILE" ]; then
    echo "[!] $FILE does not exist — creating it."
    touch "$FILE"
fi

# Ensure group 0 exists
if ! getent group "0" >/dev/null; then
    echo "[!] Group 0 does not exist — cannot remediate."
    exit 1
fi

# Fix group owner
echo "[*] Setting group owner of $FILE to 0..."
chgrp --no-dereference 0 "$FILE"

echo "[+] Remediation complete for $RULE_ID"
