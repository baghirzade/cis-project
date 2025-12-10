#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_crontab"
echo "[*] Remediating: $RULE_ID"

# Applicability check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

# Validate root exists
if ! id "0" >/dev/null 2>&1; then
    echo "[!] User 0 (root) does not exist!"
    exit 1
fi

# Apply remediation
if [ -f /etc/crontab ]; then
    CURRENT_UID=$(stat -c %u /etc/crontab)

    if [ "$CURRENT_UID" != "0" ]; then
        chown --no-dereference 0 /etc/crontab
        echo "[+] Owner of /etc/crontab corrected to root (0)"
    else
        echo "[*] /etc/crontab already owned by root (0)"
    fi
else
    echo "[!] /etc/crontab not found, nothing to remediate."
fi

echo "[+] Remediation complete for $RULE_ID"
