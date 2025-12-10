#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_owner_cron_daily"
echo "[*] Remediating: $RULE_ID"

# Applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

# Ensure root exists
if ! id "0" >/dev/null 2>&1; then
    echo "[!] User ID 0 (root) does not exist!"
    exit 1
fi

# Apply remediation
if [ -d /etc/cron.daily ]; then
    CURRENT_UID=$(stat -c %u /etc/cron.daily)

    if [ "$CURRENT_UID" != "0" ]; then
        chown --no-dereference 0 /etc/cron.daily
        echo "[+] Owner of /etc/cron.daily set to root (0)"
    else
        echo "[*] /etc/cron.daily already owned by root (0)"
    fi
else
    echo "[!] /etc/cron.daily does not exist, nothing to remediate."
fi

echo "[+] Remediation complete for $RULE_ID"
