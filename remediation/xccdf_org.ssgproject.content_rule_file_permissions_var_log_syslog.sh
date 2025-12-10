#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_syslog"
TARGET_FILE="/var/log/syslog"

echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -f "$TARGET_FILE" ]]; then
    echo "[*] File not found, nothing to remediate: $TARGET_FILE"
    exit 0
fi

chmod u-xs,g-xws,o-xwrt "$TARGET_FILE"

echo "[+] Remediation complete for: $RULE_ID"
