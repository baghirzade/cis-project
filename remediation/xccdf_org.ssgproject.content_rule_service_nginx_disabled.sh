#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_nginx_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable nginx.service)"

# Platform check (dpkg presence)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; skipping remediation."
    exit 0
fi

# linux-base must be installed for applicability
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop nginx.service unless system is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop nginx.service 2>/dev/null || true
fi

# Disable + mask main service
$SYSTEMCTL disable nginx.service || true
$SYSTEMCTL mask nginx.service || true

# Disable + mask socket unit, if it exists
if $SYSTEMCTL -q list-unit-files nginx.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop nginx.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask nginx.socket || true
fi

# Reset failure state for OVAL checks
$SYSTEMCTL reset-failed nginx.service || true

echo "[+] Remediation complete: nginx.service disabled and masked."
