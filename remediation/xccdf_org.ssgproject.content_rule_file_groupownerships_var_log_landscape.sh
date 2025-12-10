#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownerships_var_log_landscape"
echo "[*] Applying remediation for: $RULE_ID"

# Determine correct group
newgroup=""
if getent group "root" >/dev/null 2>&1; then
    newgroup="root"
elif getent group "landscape" >/dev/null 2>&1; then
    newgroup="landscape"
else
    echo "[!] Neither 'root' nor 'landscape' groups exist — cannot remediate"
    exit 1
fi

# Locate files
files=$(find -P /var/log/landscape/ -maxdepth 1 -type f -regextype posix-extended -regex '^.*$' 2>/dev/null)

if [[ -z "$files" ]]; then
    echo "[*] No files found under /var/log/landscape — nothing to remediate"
    exit 0
fi

for f in $files; do
    grp=$(stat -c %G "$f")

    if [[ "$grp" == "root" || "$grp" == "landscape" ]]; then
        echo "[*] $f already compliant (group: $grp)"
        continue
    fi

    echo "[*] Setting group '$newgroup' for $f"
    chgrp --no-dereference "$newgroup" "$f"
    echo "[+] Remediated: $f → group '$newgroup'"
done

echo "[+] Remediation completed for rule: $RULE_ID"

