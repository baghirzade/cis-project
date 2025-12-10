#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_cron_enabled"
echo "[*] Remediating: $RULE_ID"

# Check platform applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

SYSTEMCTL='/usr/bin/systemctl'

# Ensure service unmasked
$SYSTEMCTL unmask cron.service || true

# Start service if system is not offline
if [[ $($SYSTEMCTL is-system-running) != "offline" ]]; then
    $SYSTEMCTL start cron.service || true
fi

# Enable service
$SYSTEMCTL enable cron.service

echo "[+] Remediation completed for $RULE_ID"
