#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_vsftpd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable vsftpd.service)"

# dpkg platform check
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not available; skipping remediation."
    exit 0
fi

# linux-base required to apply the rule
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service if system is not offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop vsftpd.service 2>/dev/null || true
fi

# Disable & mask service
$SYSTEMCTL disable vsftpd.service || true
$SYSTEMCTL mask vsftpd.service || true

# If socket exists, stop & mask it
if $SYSTEMCTL -q list-unit-files vsftpd.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop vsftpd.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask vsftpd.socket || true
fi

# Reset failed state to satisfy OVAL checks
$SYSTEMCTL reset-failed vsftpd.service || true

echo "[+] Remediation complete: vsftpd.service disabled and masked."
