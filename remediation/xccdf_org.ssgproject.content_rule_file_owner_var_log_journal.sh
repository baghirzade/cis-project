#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_journal"
echo "[*] Applying remediation for: $RULE_ID"

# Expected user: root (UID 0)
newown=""
if id "0" >/dev/null 2>&1; then
    newown="0"
else
    echo "[!] User '0' (root) does not exist — cannot remediate"
    exit 1
fi

files=$(find -P /var/log/ -type f -regextype posix-extended -regex '.*\.journal(~)?$')

if [[ -z "$files" ]]; then
    echo "[*] No journal files found — nothing to remediate"
    exit 0
fi

for f in $files; do
    owner=$(stat -c %u "$f")

    if [[ "$owner" -eq 0 ]]; then
        echo "[*] $f already compliant (owner: root)"
        continue
    fi

    echo "[*] Fixing owner for $f → root"
    chown --no-dereference "$newown" "$f"
done

echo "[+] Remediation complete for rule: $RULE_ID"

