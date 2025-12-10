#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_package_timesyncd_installed"

echo "[*] Applying remediation for: $RULE_ID (ensure systemd-timesyncd is installed)"

# Must be Debian-based
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg missing; remediation skipped."
    exit 0
fi

# linux-base must be present
if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
   | grep -q "^installed$"; then
    echo "[!] linux-base not installed; remediation not applicable."
    exit 0
fi

# Load or default timesync variable
var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

# Only install if selected timesync backend = systemd-timesyncd
if [[ "$var_timesync_service" == "systemd-timesyncd"]()]()

cat << 'EOF' > checks/xccdf_org.ssgproject.content_rule_service_chronyd_enabled.sh
#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_service_chronyd_enabled"
TITLE="Ensure chrony.service is enabled and running when chronyd is selected"

run() {
    # Only for Debian-based systems
    if ! command -v dpkg >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|Non-Debian system"
        return 0
    fi

    # linux-base must be present
    if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|linux-base not installed"
        return 0
    fi

    # chrony package must exist for rule to apply
    if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null | grep -q installed; then
        echo "NOTAPPL|$RULE_ID|chrony package not installed"
        return 0
    fi

    # Load XCCDF variable or default
    var_timesync_service="${var_timesync_service:-systemd-timesyncd}"

    if [[ "$var_timesync_service" != "chronyd" ]]; then
        echo "NOTAPPL|$RULE_ID|chronyd not selected as timesync service"
        return 0
    fi

    SYSTEMCTL=/usr/bin/systemctl

    # Check if enabled
    if ! $SYSTEMCTL is-enabled chrony.service 2>/dev/null | grep -q enabled; then
        echo "FAIL|$RULE_ID|chrony.service is not enabled"
        return 0
    fi

    # Check if running
    if ! $SYSTEMCTL is-active chrony.service 2>/dev/null | grep -q active; then
        echo "FAIL|$RULE_ID|chrony.service is not running"
        return 0
    fi

    echo "OK|$RULE_ID|chrony.service is enabled and running"
}

if

cat << 'EOF' > remediation/xccdf_org.ssgproject.content_rule_service_chronyd_enabled.sh
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

