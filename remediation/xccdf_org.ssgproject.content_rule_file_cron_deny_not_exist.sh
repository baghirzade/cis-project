#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_cron_deny_not_exist"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/cron.deny"

if [ -f "$FILE" ]; then
    echo "[*] Removing $FILE..."
    rm -f "$FILE"
fi

echo "[+] Remediation complete for $RULE_ID"
