#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_group"
echo "[*] Applying remediation for: $RULE_ID"

# Validate root user
if ! id root >/dev/null 2>&1; then
    echo "[!] root user not found — skipping remediation"
    exit 0
fi

# Validate file exists
if [[ ! -e /etc/group ]]; then
    echo "[!] /etc/group does not exist — skipping remediation"
    exit 0
fi

current_owner=$(stat -c %U /etc/group 2>/dev/null)

if [[ "$current_owner" != "root" ]]; then
    echo "[*] Setting owner of /etc/group to root"
    chown --no-dereference root /etc/group
    echo "[+] Remediation complete"
else
    echo "[*] Already compliant"
fi

