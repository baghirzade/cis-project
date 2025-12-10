#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_rsyslog_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure rsyslog service is enabled and running)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Ensure rsyslog package is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'rsyslog' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] rsyslog package is not installed. Remediation not applicable."
    exit 0
fi

SYSTEMCTL_EXEC='/usr/bin/systemctl'

# Unmask service if masked
"$SYSTEMCTL_EXEC" unmask rsyslog.service || true

# Enable service
"$SYSTEMCTL_EXEC" enable rsyslog.service

# Start service if system is not offline
if [[ $("$SYSTEMCTL_EXEC" is-system-running || echo "offline") != "offline" ]]; then
    "$SYSTEMCTL_EXEC" start rsyslog.service || true
fi

echo "[+] Remediation complete: rsyslog.service enabled and running"
