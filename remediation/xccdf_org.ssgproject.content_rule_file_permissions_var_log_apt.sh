#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_apt"
echo "[*] Applying remediation for: $RULE_ID"

bad_files=$(find -P /var/log/apt/ -maxdepth 1 \
    -perm /u+xs,g+xws,o+xwt \
    -type f -regextype posix-extended -regex '^.*$')

if [[ -z "$bad_files" ]]; then
    echo "[*] No remediation needed."
    exit 0
fi

while IFS= read -r f; do
    echo "[*] Fixing permissions for: $f"
    chmod u-xs,g-xws,o-xwt "$f"
done <<< "$bad_files"

echo "[+] Remediation complete for rule: $RULE_ID"
