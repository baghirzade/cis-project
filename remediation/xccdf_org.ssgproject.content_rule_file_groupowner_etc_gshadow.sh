#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_gshadow"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure shadow group exists
if ! getent group shadow >/dev/null 2>&1; then
    echo "[!] shadow group not found — skipping remediation"
    exit 0
fi

# Ensure file exists
if [[ ! -e /etc/gshadow ]]; then
    echo "[!] /etc/gshadow does not exist — skipping remediation"
    exit 0
fi

current_group=$(stat -c %G /etc/gshadow 2>/dev/null)

if [[ "$current_group" != "shadow" ]]; then
    echo "[*] Setting group owner of /etc/gshadow to shadow"
    chgrp --no-dereference shadow /etc/gshadow
    echo "[+] Remediation complete"
else
    echo "[*] No changes needed — already compliant"
fi

