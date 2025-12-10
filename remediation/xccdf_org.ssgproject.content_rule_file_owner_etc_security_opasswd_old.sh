#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_etc_security_opasswd_old"
echo "[*] Applying remediation for: $RULE_ID"

# Ensure root user exists
if ! id root >/dev/null 2>&1; then
    echo "[!] root user not found — skipping remediation"
    exit 0
fi

# Ensure file exists
if [[ ! -e /etc/security/opasswd.old ]]; then
    echo "[!] /etc/security/opasswd.old does not exist — skipping remediation"
    exit 0
fi

current_owner=$(stat -c %U /etc/security/opasswd.old 2>/dev/null)

if [[ "$current_owner" != "root" ]]; then
    echo "[*] Setting owner of /etc/security/opasswd.old to root"
    chown --no-dereference root /etc/security/opasswd.old
    echo "[+] Remediation complete"
else
    echo "[*] Already compliant"
fi

