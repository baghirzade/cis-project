#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_security_opasswd"
echo "[*] Applying remediation for: $RULE_ID"

# Confirm file exists
if [[ ! -e /etc/security/opasswd ]]; then
    echo "[!] /etc/security/opasswd does not exist — skipping remediation"
    exit 0
fi

echo "[*] Setting permissions of /etc/security/opasswd to 600"
chmod 600 /etc/security/opasswd

echo "[+] Remediation complete"

