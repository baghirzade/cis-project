#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_apt"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group (prefer adm → fallback root)
newgroup=""
if getent group "adm" >/dev/null 2>&1; then
    newgroup="adm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'adm' nor 'root' group exists — cannot remediate"
    exit 1
fi

# Collect target files
files=$(find -P /var/log/apt/ -maxdepth 1 -type f -regextype posix-extended -regex '.*' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files found under /var/log/apt — nothing to remediate"
    exit 0
fi

for f in $files; do
    grp=$(stat -c %G "$f")

    if [[ "$grp" == "adm" || "$grp" == "root" ]]; then
        echo "[*] $f already compliant (group: $grp)"
        continue
    fi

    echo "[*] Setting group '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation complete for: $RULE_ID"

