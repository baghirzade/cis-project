#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_backup_etc_shadow"
echo "[*] Applying remediation for: $RULE_ID"

# Check if shadow group exists
if ! getent group shadow >/dev/null 2>&1; then
    echo "[!] shadow group not found — skipping remediation"
    exit 0
fi

# Check if file exists
if [[ ! -e /etc/shadow- ]]; then
    echo "[!] /etc/shadow- does not exist — skipping"
    exit 0
fi

current_group=$(stat -c %G /etc/shadow- 2>/dev/null)

# Fix ownership
if [[ "$current_group" != "shadow" ]]; then
    echo "[*] Setting group owner of /etc/shadow- to shadow"
    chgrp --no-dereference shadow /etc/shadow-
    echo "[+] Remediation complete"
else
    echo "[*] No changes needed — already correct"
fi

