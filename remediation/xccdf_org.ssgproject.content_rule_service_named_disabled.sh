#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_named_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable named.service)"

# Ensure dpkg present
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; skipping remediation (non-Debian system)."
    exit 0
fi

# Rule applicability requires linux-base
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service unless system is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop named.service 2>/dev/null || true
fi

# Disable and mask main service
$SYSTEMCTL disable named.service || true
$SYSTEMCTL mask named.service || true

# Socket unit handling if present
if $SYSTEMCTL -q list-unit-files named.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop named.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask named.socket || true
fi

# Reset failed state
$SYSTEMCTL reset-failed named.service || true

echo "[+] Remediation complete: named.service disabled and masked."
