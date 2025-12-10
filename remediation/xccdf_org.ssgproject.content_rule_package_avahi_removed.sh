#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_avahi_removed"
echo "[*] Remediating: $RULE_ID"

# Remove avahi-daemon package if installed
if dpkg-query --show --showformat='${db:Status-Status}' avahi-daemon 2>/dev/null | grep -q '^installed$'; then
    echo "[*] Removing avahi-daemon..."
    DEBIAN_FRONTEND=noninteractive apt-get remove -y avahi-daemon
else
    echo "[*] avahi-daemon already removed. Nothing to do."
fi

echo "[+] Remediation completed for $RULE_ID"
