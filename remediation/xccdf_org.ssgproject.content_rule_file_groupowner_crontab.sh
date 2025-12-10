#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_crontab"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

# Ensure group 0 exists
if ! getent group "0" >/dev/null 2>&1; then
    echo "[!] Group 0 does not exist on this system!"
    exit 1
fi

# Apply remediation
if [ -f /etc/crontab ]; then
    CURRENT_GID=$(stat -c %g /etc/crontab)
    if [ "$CURRENT_GID" != "0" ]; then
        chgrp --no-dereference 0 /etc/crontab
        echo "[+] Group owner of /etc/crontab set to 0 (root)"
    else
        echo "[*] /etc/crontab already has correct group owner (0)"
    fi
else
    echo "[!] /etc/crontab does not exist, nothing to remediate."
fi

echo "[+] Remediation completed for $RULE_ID"
