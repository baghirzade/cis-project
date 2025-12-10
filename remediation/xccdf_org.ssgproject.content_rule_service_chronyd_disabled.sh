#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_chronyd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable chrony.service when chronyd is not selected)"

# Debian-based platform check
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing — skipping remediation."
    exit 0
fi

# linux-base required
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q installed; then
    echo "[!] linux-base not installed — remediation not applicable."
    exit 0
fi

# chrony must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null \
    | grep -q installed; then
    echo "[!] chrony package not installed — skipping remediation."
    exit 0
fi

# Read XCCDF variable
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

SYSTEMCTL=/usr/bin/systemctl

# Only disable chrony.service if chronyd is NOT selected
if [[ "$var_timesync_service" != "chronyd" ]]; then
    echo "[*] chronyd not selected — disabling chrony.service."

    $SYSTEMCTL stop chrony.service 2>/dev/null || true
    $SYSTEMCTL disable chrony.service || true
    $SYSTEMCTL mask chrony.service || true

    # Optional socket
    if $SYSTEMCTL -q list-unit-files chrony.socket 2>/dev/null; then
        $SYSTEMCTL stop chrony.socket 2>/dev/null || true
        $SYSTEMCTL mask chrony.socket || true
    fi

    $SYSTEMCTL reset-failed chrony.service || true

    echo "[+] chrony.service disabled and masked."
else
    echo "[*] chronyd is selected — no changes applied."
fi

