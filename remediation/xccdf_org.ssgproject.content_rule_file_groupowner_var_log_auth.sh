#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_var_log_auth"
echo "[*] Applying remediation for: $RULE_ID"

if [[ ! -e /var/log/auth.log ]]; then
    echo "[!] /var/log/auth.log does not exist — skipping remediation"
    exit 0
fi

# Determine correct group
if getent group "adm" >/dev/null 2>&1; then
    newgroup="adm"
elif getent group "root" >/dev/null 2>&1; then
    newgroup="root"
else
    echo "[!] Neither 'adm' nor 'root' groups exist — cannot remediate"
    exit 1
fi

echo "[*] Setting group ownership of /var/log/auth.log to: $newgroup"
chgrp --no-dereference "$newgroup" /var/log/auth.log

echo "[+] Remediation complete"

