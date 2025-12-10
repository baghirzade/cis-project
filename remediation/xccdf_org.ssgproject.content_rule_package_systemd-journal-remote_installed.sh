#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_systemd-journal-remote_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure systemd-journal-remote is installed when rsyslog is not active)"

# Only Debian/Ubuntu
if ! command -v dpkg-query >/dev/null 2>&1; then
    echo "[!] dpkg-query not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Require linux-base (same applicability as SCAP content)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation is not applicable. Skipping."
    exit 0
fi

# If rsyslog is active, rule is not applicable (SCAP logic)
if systemctl is-active rsyslog >/dev/null 2>&1; then
    echo "[!] rsyslog service is active. This control is considered not applicable. No changes made."
    exit 0
fi

# Now ensure systemd-journal-remote is installed
if dpkg-query --show --showformat='${db:Status-Status}' 'systemd-journal-remote' 2>/dev/null | grep -q '^installed$'; then
    echo "[+] systemd-journal-remote is already installed."
    exit 0
fi

echo "[*] Installing systemd-journal-remote package..."
export DEBIAN_FRONTEND=noninteractive
apt-get update -y >/dev/null 2>&1 || true
apt-get install -y systemd-journal-remote

echo "[+] Remediation complete: systemd-journal-remote package installed."
