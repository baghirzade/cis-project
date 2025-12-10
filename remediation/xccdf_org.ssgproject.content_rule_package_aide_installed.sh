#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_aide_installed"

echo "[*] Applying remediation for: $RULE_ID (install AIDE)"

# Ensure dpkg is available
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, this remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Remediation is applicable only if linux-base is installed (SCAP logic)
if dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo " - Installing AIDE package via apt-get"
    DEBIAN_FRONTEND=noninteractive apt-get install -y aide || {
        echo "[!] Failed to install AIDE package"
        exit 1
    }
    echo "[+] Remediation complete: AIDE is now installed"
else
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
fi