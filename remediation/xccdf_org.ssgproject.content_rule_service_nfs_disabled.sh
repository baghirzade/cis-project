#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_nfs_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable nfs-server.service)"

# Ensure platform uses dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; skipping remediation."
    exit 0
fi

# linux-base required
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
   | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop NFS service unless system is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop nfs-server.service 2>/dev/null || true
fi

# Disable + mask service
$SYSTEMCTL disable nfs-server.service || true
$SYSTEMCTL mask nfs-server.service || true

# Optional socket handling
if $SYSTEMCTL -q list-unit-files nfs-server.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop nfs-server.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask nfs-server.socket || true
fi

# Reset possible failed status
$SYSTEMCTL reset-failed nfs-server.service || true

echo "[+] Remediation complete: nfs-server.service disabled and masked."
