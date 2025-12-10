#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_cron_monthly"
echo "[*] Remediating: $RULE_ID"

# Applicability check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

TARGET_DIR="/etc/cron.monthly"

if [ -d "$TARGET_DIR" ]; then
    echo "[*] Fixing permissions on $TARGET_DIR…"
    find -H "$TARGET_DIR" -maxdepth 0 -perm /u+s,g+xwrs,o+xwrt -type d \
        -exec chmod u-s,g-xwrs,o-xwrt {} \;
    echo "[+] Permissions corrected for $TARGET_DIR"
else
    echo "[!] Directory $TARGET_DIR does not exist, skipping."
fi

echo "[+] Remediation complete for $RULE_ID"
