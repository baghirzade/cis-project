#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_localmessages"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group
newgroup=""
if getent group "adm" >/dev/null 2>&1; then
    newgroup="adm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'adm' nor 'root' group exists — cannot remediate"
    exit 1
fi

# Find matching files
files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*localmessages.*')

if [[ -z "$files" ]]; then
    echo "[*] No localmessages files found — nothing to remediate"
    exit 0
fi

echo "[*] Setting group owner '$newgroup' for localmessages files"

while IFS= read -r f; do
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Fixed group ownership: $f"
done <<< "$files"

echo "[+] Remediation complete"

