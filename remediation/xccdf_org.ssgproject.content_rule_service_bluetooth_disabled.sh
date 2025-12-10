#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_bluetooth_disabled"

echo "[*] Applying remediation for: $RULE_ID (Disable and mask bluetooth service)"

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then

SYSTEMCTL_EXEC='/usr/bin/systemctl'

echo "[*] Processing bluetooth.service..."

# Stop service if system is running (to avoid error if offline)
if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
    echo "    -> Stopping bluetooth.service"
    "$SYSTEMCTL_EXEC" stop 'bluetooth.service' || true # Use || true to ignore if already stopped/not found
fi

echo "    -> Disabling and masking bluetooth.service"
"$SYSTEMCTL_EXEC" disable 'bluetooth.service' || true
"$SYSTEMCTL_EXEC" mask 'bluetooth.service' || true

# Disable socket activation if we have a unit file for it
if "$SYSTEMCTL_EXEC" -q list-unit-files bluetooth.socket; then
    echo "[*] Processing bluetooth.socket..."
    if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
      echo "    -> Stopping bluetooth.socket"
      "$SYSTEMCTL_EXEC" stop 'bluetooth.socket' || true
    fi
    echo "    -> Masking bluetooth.socket"
    "$SYSTEMCTL_EXEC" mask 'bluetooth.socket' || true
fi

# The service may not be running because it has been started and failed,
# so let's reset the state so OVAL checks pass.
# Service should be 'inactive', not 'failed' after reboot though.
echo "    -> Resetting failed state for bluetooth.service"
"$SYSTEMCTL_EXEC" reset-failed 'bluetooth.service' || true

echo "[+] Remediation complete: bluetooth service disabled and masked."

else
    >&2 echo 'Remediation is not applicable, linux-base package is not installed.'
fi
