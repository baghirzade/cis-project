#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_slapd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable slapd.service)"

# Ensure dpkg exists (Debian/Ubuntu only)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; skipping remediation."
    exit 0
fi

# Rule applies only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service unless system state is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop slapd.service 2>/dev/null || true
fi

# Disable + mask service
$SYSTEMCTL disable slapd.service || true
$SYSTEMCTL mask slapd.service || true

# Handle socket if present
if $SYSTEMCTL -q list-unit-files slapd.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop slapd.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask slapd.socket || true
fi

# Reset state so OVAL checks pass
$SYSTEMCTL reset-failed slapd.service || true

echo "[+] Remediation complete: slapd.service disabled and masked."
