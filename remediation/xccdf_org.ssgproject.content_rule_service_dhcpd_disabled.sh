#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_dhcpd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable isc-dhcp-server.service)"

# Applicability check: dpkg must be available
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; non-Debian system. Skipping."
    exit 0
fi

# Rule applies only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service (unless system is offline)
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop isc-dhcp-server.service 2>/dev/null || true
fi

# Disable + mask main service
$SYSTEMCTL disable isc-dhcp-server.service || true
$SYSTEMCTL mask isc-dhcp-server.service || true

# Handle socket unit
if $SYSTEMCTL -q list-unit-files isc-dhcp-server.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop isc-dhcp-server.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask isc-dhcp-server.socket || true
fi

# Reset failed state to satisfy OVAL checks
$SYSTEMCTL reset-failed isc-dhcp-server.service || true

echo "[+] Remediation complete: isc-dhcp-server.service disabled and masked."
