#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_avahi-daemon_disabled"
echo "[*] Remediating: $RULE_ID"

# Check platform applicability
if ! ( dpkg-query --show --showformat='${db:Status-Status}' avahi-daemon 2>/dev/null | grep -q '^installed$' \
   && dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$' ); then
    echo "[*] Not applicable, avahi-daemon or linux-base not installed."
    exit 0
fi

SYSTEMCTL_EXEC='/usr/bin/systemctl'

# Stop service if system is running
if [[ "$($SYSTEMCTL_EXEC is-system-running)" != "offline" ]]; then
    $SYSTEMCTL_EXEC stop avahi-daemon.service || true
fi

$SYSTEMCTL_EXEC disable avahi-daemon.service || true
$SYSTEMCTL_EXEC mask avahi-daemon.service || true

# Disable socket if exists
if $SYSTEMCTL_EXEC -q list-unit-files avahi-daemon.socket; then
    if [[ "$($SYSTEMCTL_EXEC is-system-running)" != "offline" ]]; then
        $SYSTEMCTL_EXEC stop avahi-daemon.socket || true
    fi
    $SYSTEMCTL_EXEC mask avahi-daemon.socket || true
fi

# Reset failed state
$SYSTEMCTL_EXEC reset-failed avahi-daemon.service || true

echo "[+] Remediation completed for $RULE_ID"
