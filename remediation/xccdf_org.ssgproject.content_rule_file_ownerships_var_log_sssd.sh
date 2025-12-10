#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_sssd"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct owner
if id "sssd" >/dev/null 2>&1; then
    target_owner="sssd"
elif id "root" >/dev/null 2>&1; then
    target_owner="root"
else
    echo "[!] Neither 'sssd' nor 'root' user exists on this system!"
    exit 1
fi

# Find non-compliant files
files=$(find -P /var/log/sssd/ -type f \
    ! -user sssd ! -user root \
    -regextype posix-extended -regex '.*')

if [[ -z "$files" ]]; then
    echo "[*] No files require remediation."
    exit 0
fi

# Correct ownership
while IFS= read -r f; do
    echo "[*] Fixing ownership: $f → $target_owner"
    chown --no-dereference "$target_owner" "$f"
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"
