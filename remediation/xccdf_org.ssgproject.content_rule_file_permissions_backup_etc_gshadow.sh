#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_backup_etc_gshadow"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure file exists
if [[ ! -e /etc/gshadow- ]]; then
    echo "[!] /etc/gshadow- does not exist — skipping remediation"
    exit 0
fi

echo "[*] Setting permissions of /etc/gshadow- to 600"
chmod 600 /etc/gshadow-

echo "[+] Remediation complete"

