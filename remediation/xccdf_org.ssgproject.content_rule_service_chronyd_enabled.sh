#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_chronyd_enabled"

echo "[*] Applying remediation for: $RULE_ID (ensure chrony.service enabled when required)"

# Must be Debian-based
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; skipping remediation."
    exit 0
fi

# linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
    echo "[!] linux-base not installed; skipping remediation."
    exit 0
fi

# chrony package must exist
if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null | grep -q installed; then
    echo "[!] chrony package not installed; skipping."
    exit 0
fi

# Read or default XCCDF variable
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

SYSTEMCTL=/usr/bin/systemctl

# Act only if chronyd is selected
if [[ "$var_timesync_service" == "chronyd" ]]; then
    echo "[*] chronyd selected — enabling chrony.service"

    $SYSTEMCTL unmask chrony.service || true
    $SYSTEMCTL enable chrony.service || true
    $SYSTEMCTL start chrony.service || true

    echo "[+] chrony.service enabled and started."
else
    echo "[*] chronyd not selected — no remediation needed."
fi

