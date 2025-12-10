#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_cron_allow"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

FILE="/etc/cron.allow"

if [ ! -f "$FILE" ]; then
    echo "[!] $FILE does not exist — creating it."
    touch "$FILE"
fi

# Ensure group exists
if ! getent group "crontab" >/dev/null 2>&1; then
    echo "[!] Group 'crontab' does not exist — cannot remediate."
    exit 1
fi

# Fix group owner
if ! stat -c "%G" "$FILE" | grep -q "^crontab$"; then
    echo "[*] Setting group owner of $FILE to 'crontab'..."
    chgrp --no-dereference "crontab" "$FILE"
fi

echo "[+] Remediation complete for $RULE_ID"
