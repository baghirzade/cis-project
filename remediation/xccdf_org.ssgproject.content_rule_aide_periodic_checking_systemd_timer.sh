#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_aide_periodic_checking_systemd_timer"

AIDE_PKG="aide"

echo "[*] Applying remediation for: $RULE_ID (configure AIDE periodic checking via systemd timer)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Check platform applicability: linux-base, aide, systemd
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

if ! dpkg -s systemd >/dev/null 2>&1 || ! command -v systemctl >/dev/null 2>&1; then
    echo "[!] systemd/systemctl not available. Remediation is not applicable. No changes applied."
    exit 0
fi

# Ensure AIDE is installed
if ! dpkg -s "$AIDE_PKG" >/dev/null 2>&1; then
    echo "[*] AIDE package is not installed, installing it now."
    DEBIAN_FRONTEND=noninteractive apt-get install -y "$AIDE_PKG"
fi

# Unmask and enable the timer and service
echo "[*] Unmasking and enabling dailyaidecheck.service and dailyaidecheck.timer"
systemctl unmask dailyaidecheck.service || true
systemctl unmask dailyaidecheck.timer || true
systemctl --now enable dailyaidecheck.timer

echo "[+] Remediation complete: dailyaidecheck.timer should now be enabled and active."