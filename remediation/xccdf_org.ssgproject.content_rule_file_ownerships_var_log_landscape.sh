#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_landscape"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct owner
if id "root" >/dev/null 2>&1; then
    target_owner="root"
elif id "landscape" >/dev/null 2>&1; then
    target_owner="landscape"
else
    echo "[!] Neither 'root' nor 'landscape' user exists on this system!"
    exit 1
fi

files=$(find -P /var/log/landscape/ -maxdepth 1 -type f \
    ! -user root ! -user landscape \
    -regextype posix-extended -regex '^.*$')

if [[ -z "$files" ]]; then
    echo "[*] No files require remediation."
    exit 0
fi

while IFS= read -r f; do
    echo "[*] Fixing ownership: \$f → \$target_owner"
    chown --no-dereference "$target_owner" "$f"
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"
