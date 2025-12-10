#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_auth"
FILE="/var/log/auth.log"

echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -f "$FILE" ]]; then
    echo "[*] File $FILE not found — skipping."
    exit 0
fi

echo "[*] Fixing permissions on $FILE"
chmod u-xs,g-xws,o-xwrt "$FILE"

echo "[+] Remediation complete for rule: $RULE_ID"
