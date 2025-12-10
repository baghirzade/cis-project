#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_systemd-journal-upload_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure systemd-journal-upload.service is enabled)"

SYSTEMCTL_EXEC="${SYSTEMCTL_EXEC:-/usr/bin/systemctl}"

# Only Debian/Ubuntu
if ! command -v dpkg-query >/dev/null 2>&1; then
    echo "[!] dpkg-query not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Same applicability as original SCAP: linux-base installed, not in container, and systemd-journal-remote installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. Skipping."
    exit 0
fi

if [ -f /.dockerenv ] || [ -f /run/.containerenv ]; then
    echo "[!] Detected container environment. Remediation is not applicable. Skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' 'systemd-journal-remote' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] systemd-journal-remote package is not installed. Remediation is not applicable. Skipping."
    exit 0
fi

if ! command -v "$SYSTEMCTL_EXEC" >/dev/null 2>&1; then
    echo "[!] systemctl not found, cannot manage systemd services. Skipping."
    exit 0
fi

echo "[*] Unmasking systemd-journal-upload.service..."
"$SYSTEMCTL_EXEC" unmask 'systemd-journal-upload.service' || true

# Sistemin vəziyyəti offline deyilsə, servisi start et
if [[ "$("$SYSTEMCTL_EXEC" is-system-running 2>/dev/null || echo "unknown")" != "offline" ]]; then
    echo "[*] Starting systemd-journal-upload.service..."
    "$SYSTEMCTL_EXEC" start 'systemd-journal-upload.service' || true
else
    echo "[!] System is in 'offline' state, will only enable the service without starting it."
fi

echo "[*] Enabling systemd-journal-upload.service to start at boot..."
"$SYSTEMCTL_EXEC" enable 'systemd-journal-upload.service'

echo "[+] Remediation complete: systemd-journal-upload.service is unmasked and enabled (started if possible)."
