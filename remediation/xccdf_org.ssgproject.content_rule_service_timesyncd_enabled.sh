#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_timesyncd_enabled"

echo "[*] Applying remediation for: $RULE_ID (enable systemd-timesyncd.service)"

# Must be Debian-based
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; skipping remediation."
    exit 0
fi

# linux-base must exist
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
    echo "[!] linux-base not installed; skipping remediation."
    exit 0
fi

# Rule applies only if chrony AND ntp are NOT installed
if dpkg -s chrony >/dev/null 2>&1 || dpkg -s ntp >/dev/null 2>&1; then
    echo "[*] chrony or ntp installed — timesyncd not required. No changes."
    exit 0
fi

# Load XCCDF variable or default
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

SYSTEMCTL=/usr/bin/systemctl

if [[ "$var_timesync_service" == "systemd-timesyncd" ]]; then
    echo "[*] systemd-timesyncd selected — enabling service"

    $SYSTEMCTL unmask systemd-timesyncd.service || true
    $SYSTEMCTL enable systemd-timesyncd.service || true
    $SYSTEMCTL start systemd-timesyncd.service || true

    echo "[+] systemd-timesyncd.service enabled and started."
else
    echo "[*] systemd-timesyncd not selected — skipping remediation."
fi

