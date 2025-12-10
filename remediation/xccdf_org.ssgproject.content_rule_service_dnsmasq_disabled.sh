#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_dnsmasq_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable dnsmasq.service)"

# Ensure Debian-based system
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; skipping remediation."
    exit 0
fi

# Rule applicable only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service if system is not offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop dnsmasq.service 2>/dev/null || true
fi

# Disable and mask service
$SYSTEMCTL disable dnsmasq.service || true
$SYSTEMCTL mask dnsmasq.service || true

# Handle socket
if $SYSTEMCTL -q list-unit-files dnsmasq.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop dnsmasq.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask dnsmasq.socket || true
fi

# Reset state for OVAL compliance
$SYSTEMCTL reset-failed dnsmasq.service || true

echo "[+] Remediation complete: dnsmasq.service disabled and masked."
