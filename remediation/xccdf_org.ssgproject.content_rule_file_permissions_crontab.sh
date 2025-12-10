#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_crontab"
echo "[*] Remediating: $RULE_ID"

# Applicability check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

TARGET="/etc/crontab"

if [ -f "$TARGET" ]; then
    echo "[*] Fixing permissions on $TARGET …"
    chmod u-xs,g-xwrs,o-xwrt "$TARGET"
    echo "[+] Permissions corrected for $TARGET"
else
    echo "[!] File $TARGET does not exist, skipping."
fi

echo "[+] Remediation complete for $RULE_ID"
