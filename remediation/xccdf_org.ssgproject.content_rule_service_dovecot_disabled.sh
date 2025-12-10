#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_service_dovecot_disabled"

echo "[*] Applying remediation for: $RULE_ID (disable dovecot.service)"

# Ensure system is Debian-based
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found; remediation skipped."
    exit 0
fi

# Rule applicability: linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q '^installed$'; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

SYSTEMCTL="/usr/bin/systemctl"

# Stop the service unless system is offline
if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
    $SYSTEMCTL stop dovecot.service 2>/dev/null || true
fi

# Disable + mask service
$SYSTEMCTL disable dovecot.service || true
$SYSTEMCTL mask dovecot.service || true

# Handle socket activation if present
if $SYSTEMCTL -q list-unit-files dovecot.socket 2>/dev/null; then
    if [[ "$($SYSTEMCTL is-system-running 2>/dev/null || echo running)" != "offline" ]]; then
        $SYSTEMCTL stop dovecot.socket 2>/dev/null || true
    fi
    $SYSTEMCTL mask dovecot.socket || true
fi

# Reset failed state for OVAL compliance

cat << 'EOF' > checks/xccdf_org.ssgproject.content_rule_package_openldap-clients_removed.sh
#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_package_openldap-clients_removed"
TITLE="Ensure ldap-utils package is removed"

run() {
    # Only for dpkg-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|dpkg not available (non-Debian/Ubuntu system)"
        return 0
    fi

    # Check ldap-utils installation
    if ! dpkg -s ldap-utils >/dev/null 2>&1; then
        echo "OK|$RULE_ID|ldap-utils package is not installed"
        return 0
    fi

    echo "FAIL|$RULE_ID|ldap-utils package is installed and must be removed"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
