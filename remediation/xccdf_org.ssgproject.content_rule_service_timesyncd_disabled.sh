#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable systemd-timesyncd.service)"

# Debian check
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing — skipping remediation."
    exit 0
fi

# linux-base check
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q installed; then
    echo "[!] linux-base not installed — remediation not applicable."
    exit 0
fi

# package check
if ! dpkg-query --show --showformat='${db:Status-Status}' systemd-timesyncd 2>/dev/null \
    | grep -q installed; then
    echo "[!] systemd-timesyncd not installed — skipping remediation."
    exit 0
fi

# XCCDF variable (default)
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

SYSTEMCTL=/usr/bin/systemctl

# Only disable if systemd-timesyncd is NOT the selected sync backend
if [[ "$var_timesync_service" != "systemd-timesyncd" ]]; then
    echo "[*] systemd-timesyncd not selected — disabling service."

    $SYSTEMCTL stop systemd-timesyncd.service 2>/dev/null || true
    $SYSTEMCTL disable systemd-timesyncd.service || true
    $SYSTEMCTL mask systemd-timesyncd.service || true

    # Optional socket
    if $SYSTEMCTL -q list-unit-files systemd-timesyncd.socket 2>/dev/null; then
        $SYSTEMCTL stop systemd-timesyncd.socket 2>/dev/null || true
        $SYSTEMCTL mask systemd-timesyncd.socket || true
    fi

    # reset-failed to satisfy OVAL
    $SYSTEMCTL reset-failed systemd-timesyncd.service || true

    echo "[+] systemd-timesyncd.service disabled and masked."
else
    echo "[*] systemd-timesyncd is selected — no remediation needed."
fi

