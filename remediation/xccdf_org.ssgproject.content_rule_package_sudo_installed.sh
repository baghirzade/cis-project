#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_sudo_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure sudo package is installed)"

# Only Debian/Ubuntu systems have dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicability: only when linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# If sudo is already installed, do nothing
if dpkg-query --show --showformat='${db:Status-Status}' 'sudo' 2>/dev/null | grep -q '^installed$'; then
    echo "[i] sudo package is already installed. Nothing to do."
    exit 0
fi

echo "[*] Installing sudo package via apt-get..."
DEBIAN_FRONTEND=noninteractive apt-get update -y >/dev/null 2>&1 || true
DEBIAN_FRONTEND=noninteractive apt-get install -y "sudo"

echo "[+] Remediation complete: sudo package installed."
