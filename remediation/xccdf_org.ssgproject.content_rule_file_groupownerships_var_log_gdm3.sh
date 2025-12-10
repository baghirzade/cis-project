#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_gdm3"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group (prefer gdm → fallback gdm3 → fallback root)
newgroup=""
if getent group "gdm" >/dev/null 2>&1; then
    newgroup="gdm"
elif getent group "gdm3" >/dev/null 2>&1; then
    newgroup="gdm3"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] None of 'gdm', 'gdm3', or 'root' exist — cannot remediate"
    exit 1
fi

# Locate files
files=$(find -P /var/log/gdm3/ -type f -regextype posix-extended -regex '.*' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files found under /var/log/gdm3 — nothing to remediate"
    exit 0
fi

for f in $files; do
    grp=$(stat -c %G "$f")

    if [[ "$grp" == "gdm" || "$grp" == "gdm3" || "$grp" == "root" ]]; then
        echo "[*] $f already compliant (group: $grp)"
        continue
    fi

    echo "[*] Setting group '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation completed for rule: $RULE_ID"

