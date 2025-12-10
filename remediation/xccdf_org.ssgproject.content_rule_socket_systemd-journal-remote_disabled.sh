#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_socket_systemd-journal-remote_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable systemd-journal-remote.socket)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicable only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

SYSTEMCTL_EXEC='/usr/bin/systemctl'
SOCKET_NAME="systemd-journal-remote.socket"

if "$SYSTEMCTL_EXEC" -q list-unit-files --type socket | grep -q "$SOCKET_NAME"; then
    # Stop if running
    if [[ $("$SYSTEMCTL_EXEC" is-system-running) != "offline" ]]; then
        "$SYSTEMCTL_EXEC" stop "$SOCKET_NAME" || true
    fi
    # Mask to disable permanently
    "$SYSTEMCTL_EXEC" mask "$SOCKET_NAME"
    echo "[+] Remediation complete: $SOCKET_NAME stopped and masked."
else
    echo "[!] $SOCKET_NAME not found. No changes applied."
fi
