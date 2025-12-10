#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_chrony_installed"

echo "[*] Applying remediation for: $RULE_ID (install chrony if chronyd is selected)"

# Applicability checks
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; skipping remediation."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
   | grep -q '^installed$'; then
    echo "[!] linux-base not installed; skipping remediation."
    exit 0
fi

# Get variable or fallback
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

# Only act if chronyd is selected
if [[ "$var_timesync_service" == "chronyd" ]]; then
    echo "[*] chronyd selected, ensuring chrony is installed..."

    DEBIAN_FRONTEND=noninteractive apt-get install -y chrony || true

    echo "[+] chrony installed."
else
    echo "[*] chronyd not selected; no changes required."
fi

