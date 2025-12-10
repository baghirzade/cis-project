#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_etc_shadow"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure file exists
if [[ ! -e /etc/shadow ]]; then
    echo "[!] /etc/shadow does not exist — skipping remediation"
    exit 0
fi

echo "[*] Setting permissions of /etc/shadow to 600"
chmod 600 /etc/shadow

echo "[+] Remediation complete"

