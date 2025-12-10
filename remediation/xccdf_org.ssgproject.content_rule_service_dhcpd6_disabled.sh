#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_dhcpd6_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable isc-dhcp-server6)"

# Applicability: dpkg must exist
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not available. Not a Debian-based system. Skipping."
    exit 0
fi

# Rule applicable only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop service if system is not in offline state
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo "running")" != "offline" ]]; then
    $SYSTEMCTL stop isc-dhcp-server6.service 2>/dev/null || true
fi

# Disable and mask service
$SYSTEMCTL disable isc-dhcp-server6.service || true
$SYSTEMCTL mask isc-dhcp-server6.service || true

# Handle socket unit
if $SYSTEMCTL -q list-unit-files isc-dhcp-server6.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo "running")" != "offline" ]]; then
        $SYSTEMCTL stop isc-dhcp-server6.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask isc-dhcp-server6.socket || true
fi

# Reset failure state if any
$SYSTEMCTL reset-failed isc-dhcp-server6.service || true

echo "[+] Remediation complete: isc-dhcp-server6.service disabled and masked."
