#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_shadow"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure shadow group exists
if ! getent group shadow >/dev/null 2>&1; then
    echo "[!] shadow group not found — skipping remediation"
    exit 0
fi

# Ensure file exists
if [[ ! -e /etc/shadow ]]; then
    echo "[!] /etc/shadow does not exist — skipping remediation"
    exit 0
fi

current_group=$(stat -c %G /etc/shadow 2>/dev/null)

if [[ "$current_group" != "shadow" ]]; then
    echo "[*] Setting group owner of /etc/shadow to shadow"
    chgrp --no-dereference shadow /etc/shadow
    echo "[+] Remediation complete"
else
    echo "[*] Already compliant"
fi

