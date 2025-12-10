#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_secure"
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

files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*secure(.*[-\.].*)?' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No /var/log/secure files found — nothing to remediate"
    exit 0
fi

for f in $files; do
    current_group=$(stat -c %G "$f")

    if [[ "$current_group" == "adm" || "$current_group" == "root" ]]; then
        echo "[*] $f already compliant (group: $current_group)"
        continue
    fi

    echo "[*] Setting group owner '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation complete for rule: $RULE_ID"

