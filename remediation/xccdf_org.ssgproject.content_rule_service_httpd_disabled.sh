#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_httpd_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable apache2.service)"

# Ensure platform is Debian-based
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; skipping remediation."
    exit 0
fi

# Rule applicable only if linux-base is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop apache2.service unless system is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop apache2.service 2>/dev/null || true
fi

# Disable and mask service
$SYSTEMCTL disable apache2.service || true
$SYSTEMCTL mask apache2.service || true

# Also handle socket activation if present
if $SYSTEMCTL -q list-unit-files apache2.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop apache2.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask apache2.socket || true
fi

# Reset failure state for OVAL compliance
$SYSTEMCTL reset-failed apache2.service || true

echo "[+] Remediation complete: apache2.service disabled a

cat << 'EOF' > checks/xccdf_org.ssgproject.content_rule_package_nginx_removed.sh
#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_nginx_removed"
TITLE="Ensure nginx package is removed"

run() {
    # dpkg required → Debian/Ubuntu only
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not found (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check nginx installation
    if ! dpkg -s nginx >/dev/null 2>&1; then
        echo "OK|$RULE_ID|nginx package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|nginx package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
