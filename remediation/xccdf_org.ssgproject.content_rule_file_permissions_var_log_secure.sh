#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_secure"
FILE="/var/log/secure"

echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -f "$FILE" ]]; then
    echo "[*] File not found, nothing to remediate: $FILE"
    exit 0
fi

chmod u-xs,g-xws,o-xwrt "$FILE"

echo "[+] Remediation complete for: $RULE_ID"
