#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_backup_etc_gshadow"
echo "[*] Applying remediation for: $RULE_ID"

# Check if shadow group exists
if ! getent group shadow >/dev/null 2>&1; then
    echo "[!] shadow group not found — skipping remediation"
    exit 0
fi

# Check presence of file
if [[ ! -e /etc/gshadow- ]]; then
    echo "[!] /etc/gshadow- file does not exist — skipping"
    exit 0
fi

# Fix groupownership if needed
current_group=$(stat -c %G /etc/gshadow- 2>/dev/null)

if [[ "$current_group" != "shadow" ]]; then
    echo "[*] Setting group owner of /etc/gshadow- to shadow"
    chgrp --no-dereference shadow /etc/gshadow-
    echo "[+] Remediation complete: /etc/gshadow- group owner set to shadow"
else
    echo "[*] No remediation needed — group owner already correct"
fi

