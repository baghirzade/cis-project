#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_sssd"
TARGET_DIR="/var/log/sssd"

echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -d "$TARGET_DIR" ]]; then
    echo "[*] Directory not found, nothing to remediate: $TARGET_DIR"
    exit 0
fi

find -P "$TARGET_DIR" \
    -type f \
    -perm /u+xs,g+xs,o+rwtx \
    -exec chmod u-xs,g-xs,o-xwrt {} \;

echo "[+] Remediation complete for: $RULE_ID"
