#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_var_log_auth"
echo "[*] Applying remediation for: $RULE_ID"

target_file="/var/log/auth.log"

if [[ ! -f "$target_file" ]]; then
    echo "[*] $target_file does not exist — nothing to remediate"
    exit 0
fi

# Select correct owner
newown=""
if id "syslog" >/dev/null 2>&1; then
    newown="syslog"
elif id "root" >/dev/null 2>&1; then
    newown="root"
else
    echo "[!] Neither 'syslog' nor 'root' users exist — cannot remediate"
    exit 1
fi

current_owner=$(stat -c %U "$target_file")

if [[ "$current_owner" == "syslog" || "$current_owner" == "root" ]]; then
    echo "[*] $target_file already compliant (owner: $current_owner)"
    exit 0
fi

echo "[*] Setting owner '$newown' for $target_file"
chown --no-dereference "$newown" "$target_file"

echo "[+] Remediated: $target_file → owner '$newown'"
echo "[+] Remediation completed for rule: $RULE_ID"

