#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_at_deny"
echo "[*] Remediating: $RULE_ID"

# Applicability check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/at.deny"

# Ensure file exists
if [ ! -f "$FILE" ]; then
    echo "[!] $FILE does not exist — creating it."
    touch "$FILE"
fi

# Ensure root exists
if ! id "0" >/dev/null 2>&1; then
    echo "[!] Root user (UID 0) not found — cannot remediate."
    exit 1
fi

CURRENT_UID=$(stat -c "%u" "$FILE")

if [ "$CURRENT_UID" != "0" ]; then
    echo "[*] Setting owner of $FILE to root (UID 0)..."
    chown --no-dereference 0 "$FILE"
fi

echo "[+] Remediation complete for $RULE_ID"
