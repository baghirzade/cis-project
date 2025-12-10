#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_messages"
FILE="/var/log/messages"

echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -f "$FILE" ]]; then
    echo "[*] File does not exist, nothing to fix: $FILE"
    exit 0
fi

chmod u-xs,g-xws,o-xwrt "$FILE"

echo "[+] Remediation complete for: $RULE_ID"
