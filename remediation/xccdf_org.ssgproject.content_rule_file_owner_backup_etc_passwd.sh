#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_backup_etc_passwd"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure root exists
if ! id root >/dev/null 2>&1; then
    echo "[!] root user not found — skipping remediation"
    exit 0
fi

# Ensure file exists
if [[ ! -e /etc/passwd- ]]; then
    echo "[!] /etc/passwd- does not exist — skipping remediation"
    exit 0
fi

current_owner=$(stat -c %U /etc/passwd- 2>/dev/null)

if [[ "$current_owner" != "root" ]]; then
    echo "[*] Setting owner of /etc/passwd- to root"
    chown --no-dereference root /etc/passwd-
    echo "[+] Remediation complete"
else
    echo "[*] Already compliant"
fi

