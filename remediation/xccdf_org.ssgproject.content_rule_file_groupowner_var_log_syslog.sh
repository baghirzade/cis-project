#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_syslog"
echo "[*] Applying remediation for: $RULE_ID"

file="/var/log/syslog"

if [[ ! -f "$file" ]]; then
    echo "[*] /var/log/syslog not found — nothing to remediate"
    exit 0
fi

# Determine correct group
newgroup=""
if getent group "adm" >/dev/null 2>&1; then
    newgroup="adm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'adm' nor 'root' group exists — cannot remediate"
    exit 1
fi

current_group=$(stat -c %G "$file")

if [[ "$current_group" == "adm" || "$current_group" == "root" ]]; then
    echo "[*] Already compliant: $file group is '$current_group'"
    exit 0
fi

echo "[*] Setting group owner '$newgroup' for $file"
chgrp --no-dereference "$newgroup" "$file"

echo "[+] Remediation complete: $file → group '$newgroup'"

