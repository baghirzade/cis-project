#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_rpcbind_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable rpcbind.service)"

# Ensure Debian platform
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; remediation skipped."
    exit 0
fi

# linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
   | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service unless offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop rpcbind.service 2>/dev/null || true
fi

# Disable & mask
$SYSTEMCTL disable rpcbind.service || true
$SYSTEMCTL mask rpcbind.service || true

# Optional socket
if $SYSTEMCTL -q list-unit-files rpcbind.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop rpcbind.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask rpcbind.socket || true
fi

# Reset failed state to ensure OVAL compliance
$SYSTEMCTL reset-failed rpcbind.service || true

echo "[+] Remediation complete: rpcbind.service disabled and masked."
