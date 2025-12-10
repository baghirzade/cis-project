#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupowner_cron_monthly"
echo "[*] Remediating: $RULE_ID"

# Check applicability
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
if [ -d /etc/cron.monthly ]; then
    chgrp --no-dereference 0 /etc/cron.monthly
    echo "[+] Group owner for /etc/cron.monthly set to 0 (root)"
else
    echo "[!] /etc/cron.monthly does not exist, nothing to remediate."
fi

echo "[+] Remediation completed for $RULE_ID"
