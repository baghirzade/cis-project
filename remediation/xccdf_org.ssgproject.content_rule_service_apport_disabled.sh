#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_apport_disabled"
echo "[*] Remediating: $RULE_ID"

# Only applicable if apport package is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' apport 2>/dev/null | grep -q '^installed$'; then
    echo "[*] apport not installed → skipping remediation."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service if system is not offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null)" != "offline" ]]; then
    $SYSTEMCTL stop apport.service || true
fi

$SYSTEMCTL disable apport.service || true
$SYSTEMCTL mask apport.service || true

# Handle apport.socket if exists
if $SYSTEMCTL -q list-unit-files apport.socket; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null)" != "offline" ]]; then
        $SYSTEMCTL stop apport.socket || true
    fi
    $SYSTEMCTL mask apport.socket || true
fi

# Reset failed state to satisfy OVAL check
$SYSTEMCTL reset-failed apport.service || true

echo "[+] apport service is now disabled and masked."
