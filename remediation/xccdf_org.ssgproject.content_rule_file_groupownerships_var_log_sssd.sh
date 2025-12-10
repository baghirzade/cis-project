#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_sssd"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group
newgroup=""
if getent group "sssd" >/dev/null 2>&1; then
    newgroup="sssd"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'sssd' nor 'root' groups exist — cannot remediate"
    exit 1
fi

# Find files
files=$(find -P /var/log/sssd/ -type f -regextype posix-extended -regex '.*' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files found under /var/log/sssd — nothing to remediate"
    exit 0
fi

# Remediation
for f in $files; do
    grp=$(stat -c %G "$f")

    if [[ "$grp" == "sssd" || "$grp" == "root" ]]; then
        echo "[*] $f already compliant (group: $grp)"
        continue
    fi

    echo "[*] Setting group '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation completed for rule: $RULE_ID"

