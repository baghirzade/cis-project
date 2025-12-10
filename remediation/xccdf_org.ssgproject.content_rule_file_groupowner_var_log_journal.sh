#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_journal"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct target group
newgroup=""
if getent group "systemd-journal" >/dev/null 2>&1; then
    newgroup="systemd-journal"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Groups 'systemd-journal' and 'root' do not exist — cannot remediate"
    exit 1
fi

# Find journal files
files=$(find -P /var/log/ -type f -regextype posix-extended -regex '.*\.journal[~]?')

if [[ -z "$files" ]]; then
    echo "[!] No .journal or .journal~ files found — nothing to remediate"
    exit 0
fi

echo "[*] Setting group owner of journal files to '$newgroup'"

while IFS= read -r f; do
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Fixed group ownership: $f"
done <<< "$files"

echo "[+] Remediation complete"

