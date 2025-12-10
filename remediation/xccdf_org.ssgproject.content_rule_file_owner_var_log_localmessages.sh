#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_localmessages"
echo "[*] Applying remediation for: $RULE_ID"

newown=""
if id "syslog" >/dev/null 2>&1; then
    newown="syslog"
elif id "root" >/dev/null 2>&1; then
    newown="root"
else
    echo "[!] Neither syslog nor root users exist — cannot remediate"
    exit 1
fi

files=$(find -P /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*localmessages.*')

if [[ -z "$files" ]]; then
    echo "[*] No localmessages files found — nothing to remediate"
    exit 0
fi

for f in $files; do
    owner=$(stat -c %U "$f")

    if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
        echo "[*] $f already compliant (owner: $owner)"
        continue
    fi

    echo "[*] Fixing owner for $f → $newown"
    chown --no-dereference "$newown" "$f"
done

echo "[+] Remediation complete for rule: $RULE_ID"

