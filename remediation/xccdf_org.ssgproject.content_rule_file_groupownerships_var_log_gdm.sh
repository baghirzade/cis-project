#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_gdm"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group (prefer gdm → fallback root)
newgroup=""
if getent group "gdm" >/dev/null 2>&1; then
    newgroup="gdm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'gdm' nor 'root' group exists — cannot remediate"
    exit 1
fi

# Find all files in /var/log/gdm
files=$(find -P /var/log/gdm/ -type f -regextype posix-extended -regex '.*' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files found under /var/log/gdm — nothing to remediate"
    exit 0
fi

for f in $files; do
    grp=$(stat -c %G "$f")

    if [[ "$grp" == "gdm" || "$grp" == "root" ]]; then
        echo "[*] $f already compliant (group: $grp)"
        continue
    fi

    echo "[*] Setting group '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation completed for rule: $RULE_ID"

