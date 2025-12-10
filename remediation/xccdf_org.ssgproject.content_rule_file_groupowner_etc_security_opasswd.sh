#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_etc_security_opasswd"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure root group exists
if ! getent group root >/dev/null 2>&1; then
    echo "[!] root group not found — skipping remediation"
    exit 0
fi

# Ensure file exists
if [[ ! -e /etc/security/opasswd ]]; then
    echo "[!] /etc/security/opasswd does not exist — skipping remediation"
    exit 0
fi

current_group=$(stat -c %G /etc/security/opasswd 2>/dev/null)

if [[ "$current_group" != "root" ]]; then
    echo "[*] Setting group owner of /etc/security/opasswd to root"
    chgrp --no-dereference root /etc/security/opasswd
    echo "[+] Remediation complete"
else
    echo "[*] Already compliant"
fi

