#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_lastlog"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct target group
newgroup=""
if getent group "utmp" >/dev/null 2>&1; then
    newgroup="utmp"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Groups 'utmp' and 'root' do not exist — cannot remediate"
    exit 1
fi

# Find lastlog variants
files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*lastlog(\.[^/]+)?')

if [[ -z "$files" ]]; then
    echo "[!] No lastlog files found — nothing to remediate"
    exit 0
fi

echo "[*] Setting group owner to '$newgroup' for lastlog files"

while IFS= read -r f; do
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Fixed group ownership: $f"
done <<< "$files"

echo "[+] Remediation complete"

