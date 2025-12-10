#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_gdm3"
echo "[*] Applying remediation for: $RULE_ID"

target_owner="0"

files=$(find -P /var/log/gdm3/ -type f \
    ! -user 0 \
    -regextype posix-extended -regex '.*')

if [[ -z "$files" ]]; then
    echo "[*] No files require remediation."
    exit 0
fi

while IFS= read -r f; do
    echo "[*] Fixing ownership: $f → root"
    chown --no-dereference "$target_owner" "$f"
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"
