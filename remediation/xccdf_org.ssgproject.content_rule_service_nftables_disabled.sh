#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_nftables_disabled"

echo "[*] Applying remediation for: $RULE_ID"

# Ensure nftables + linux-base are installed
if ! dpkg-query --show --showformat='${db:Status-Status}' nftables \
    2>/dev/null | grep -q '^installed$' || \
   ! dpkg-query --show --showformat='${db:Status-Status}' linux-base \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables or linux-base missing — remediation not applicable"
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

echo "[*] Disabling nftables.service..."

$SYSTEMCTL stop nftables.service || true
$SYSTEMCTL disable nftables.service || true
$SYSTEMCTL mask nftables.service || true

# If nftables.socket exists, disable it too
if $SYSTEMCTL -q list-unit-files nftables.socket; then
    echo "[*] Disabling nftables.socket..."
    $SYSTEMCTL stop nftables.socket || true
    $SYSTEMCTL mask nftables.socket || true
fi

# Clear failed state if any
echo "[*] Resetting failed state..."
$SYSTEMCTL reset-failed nftables.service || true

echo "[+] Remediation complete: nftables service disabled and masked"
