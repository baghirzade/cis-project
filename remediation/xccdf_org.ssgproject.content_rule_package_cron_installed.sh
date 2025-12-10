#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_cron_installed"
echo "[*] Remediating: $RULE_ID"

# Check platform applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Not applicable: linux-base not installed."
    exit 0
fi

# Install cron
DEBIAN_FRONTEND=noninteractive apt-get install -y cron

echo "[+] Remediation completed for $RULE_ID"
