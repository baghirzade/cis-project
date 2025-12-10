#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_wbtmp"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure root user exists
newown=""
if id "0" >/dev/null 2>&1; then
    newown="0"
else
    echo "[!] root (UID 0) does not exist — cannot remediate"
    exit 1
fi

# Find matching files
files=$(find /var/log/ -maxdepth 1 -type f -regextype posix-extended \
    -regex '.*(b|w)tmp((\.|-)[^/]+)?$')

if [[ -z "$files" ]]; then
    echo "[*] No wtmp/btmp log files found — nothing to remediate"
    exit 0
fi

# Apply fixes
while IFS= read -r f; do
    owner=$(stat -c %U "$f")

    if [[ "$owner" == "root" ]]; then
        echo "[*] $f already compliant (owner: root)"
    else
        echo "[*] Fixing owner of $f → root"
        chown --no-dereference "$newown" "$f"
    fi
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"

