#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_messages"
echo "[*] Applying remediation for: $RULE_ID"

target="/var/log/messages"

if [[ ! -f "$target" ]]; then
    echo "[*] File $target does not exist — nothing to remediate"
    exit 0
fi

newown=""
if id "syslog" >/dev/null 2>&1; then
    newown="syslog"
elif id "root" >/dev/null 2>&1; then
    newown="root"
else
    echo "[!] Neither syslog nor root user exists — cannot remediate"
    exit 1
fi

owner=$(stat -c %U "$target")

if [[ "$owner" == "syslog" || "$owner" == "root" ]]; then
    echo "[*] $target already compliant (owner: $owner)"
else
    echo "[*] Fixing owner of $target → $newown"
    chown --no-dereference "$newown" "$target"
fi

echo "[+] Remediation complete for rule: $RULE_ID"

