#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_waagent"
echo "[*] Applying remediation for: $RULE_ID"

# Determine valid owner
newown=""
if id "syslog" >/dev/null 2>&1; then
    newown="syslog"
elif id "root" >/dev/null 2>&1; then
    newown="root"
else
    echo "[!] syslog and root users do not exist — cannot remediate"
    exit 1
fi

files=$(find /var/log/ -maxdepth 1 -type f -regextype posix-extended -regex '.*waagent\.log.*')

if [[ -z "$files" ]]; then
    echo "[*] No waagent log files found — nothing to remediate"
    exit 0
fi

while IFS= read -r f; do
    owner=$(stat -c %U "$f")

    if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
        echo "[*] $f already compliant (owner: $owner)"
    else
        echo "[*] Fixing owner of $f → $newown"
        chown --no-dereference "$newown" "$f"
    fi
done <<< "$files"

echo "[+] Remediation complete for rule: $RULE_ID"

