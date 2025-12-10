#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_snmpd_disabled"

echo "[*] Applying remediation for: $RULE_ID (Disable SNMP service)"

# Remediation is applicable only in certain platforms
if ( dpkg-query --show --showformat='${db:Status-Status}' 'snmp' 2>/dev/null | grep -q '^installed$' && dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$' ); then

SYSTEMCTL_EXEC='/usr/bin/systemctl'
SERVICE_NAME='snmpd.service'
SOCKET_NAME='snmpd.socket'

echo "    -> Stopping, disabling, and masking $SERVICE_NAME"

# Stop the service if it is running
if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
  "$SYSTEMCTL_EXEC" stop "$SERVICE_NAME" || true
fi

# Disable and Mask the service
"$SYSTEMCTL_EXEC" disable "$SERVICE_NAME" || true
"$SYSTEMCTL_EXEC" mask "$SERVICE_NAME" || true

# Disable socket activation if a unit file for it exists
if "$SYSTEMCTL_EXEC" -q list-unit-files "$SOCKET_NAME"; then
    echo "    -> Stopping and masking socket unit $SOCKET_NAME"
    if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
      "$SYSTEMCTL_EXEC" stop "$SOCKET_NAME" || true
    fi
    "$SYSTEMCTL_EXEC" mask "$SOCKET_NAME" || true
fi

# Reset the failed state to ensure OVAL/Check scripts pass cleanly
"$SYSTEMCTL_EXEC" reset-failed "$SERVICE_NAME" || true

echo "[+] Remediation complete. SNMP service is disabled and masked."

else
    >&2 echo 'Remediation is not applicable, snmp package is not installed or platform check failed.'
fi
