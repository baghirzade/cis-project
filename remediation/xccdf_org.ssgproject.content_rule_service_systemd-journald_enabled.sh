#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_systemd-journald_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure systemd-journald.service is enabled)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Follow upstream applicability: linux-base installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation not applicable. Skipping."
    exit 0
fi

if ! command -v systemctl >/dev/null 2>&1 || [ ! -d /run/systemd/system ]; then
    echo "[!] systemd is not the init system. Remediation not applicable. Skipping."
    exit 0
fi

SYSTEMCTL_EXEC='/usr/bin/systemctl'
SERVICE_NAME='systemd-journald.service'

echo "[*] Unmasking $SERVICE_NAME (if masked)..."
"$SYSTEMCTL_EXEC" unmask "$SERVICE_NAME" || true

# Start service if system is not in 'offline' state
if [[ $("$SYSTEMCTL_EXEC" is-system-running 2>/dev/null || echo "running") != "offline" ]]; then
    echo "[*] Starting $SERVICE_NAME..."
    "$SYSTEMCTL_EXEC" start "$SERVICE_NAME" || true
fi

echo "[*] Enabling $SERVICE_NAME to start at boot..."
"$SYSTEMCTL_EXEC" enable "$SERVICE_NAME"

echo "[+] Remediation complete: $SERVICE_NAME is unmasked and enabled."
