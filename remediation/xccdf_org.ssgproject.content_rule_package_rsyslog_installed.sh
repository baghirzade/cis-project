#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_rsyslog_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure rsyslog package is installed)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Check if rsyslog is already installed
if dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
    echo "[+] rsyslog is already installed. No changes applied."
    exit 0
fi

# Install rsyslog
DEBIAN_FRONTEND=noninteractive apt-get install -y rsyslog

if dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
    echo "[+] Remediation complete: rsyslog package installed successfully."
else
    echo "[!] Remediation attempted but rsyslog package is still not installed."
fi
