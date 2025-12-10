#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_journald_disable_forward_to_syslog"

echo "[*] Applying remediation for: $RULE_ID (systemd-journald ForwardToSyslog=no)"

# Remediation is applicable only on Debian/Ubuntu-like systems with dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# SCAP remediation condition: linux-base and systemd installed, rsyslog NOT active
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation not applicable. Skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' 'systemd' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] systemd package is not installed. Remediation not applicable. Skipping."
    exit 0
fi

if systemctl is-active rsyslog >/dev/null 2>&1; then
    echo "[!] rsyslog service is active. Journald is not the sole logger; remediation not applicable. Skipping."
    exit 0
fi

CONF="/etc/systemd/journald.conf"

# Ensure config file exists
if [ -e "$CONF" ] ; then
    # Drop any existing ForwardToSyslog= lines
    LC_ALL=C sed -i "/^[[:space:]]*ForwardToSyslog[[:space:]]*=/d" "$CONF"
else
    touch "$CONF"
fi

# make sure file has newline at the end
sed -i -e '$a\' "$CONF"

cp "$CONF" "${CONF}.bak"

# Insert before the line matching the regex '^#\s*ForwardToSyslog'
line_number="$(LC_ALL=C grep -n "^#\s*ForwardToSyslog" "${CONF}.bak" | LC_ALL=C sed 's/:.*//g')"

if [ -z "$line_number" ]; then
    # No commented ForwardToSyslog line; append at the end
    printf '%s\n' "ForwardToSyslog=no" >> "$CONF"
else
    # Rebuild file to insert ForwardToSyslog=no before the comment
    head -n "$(( line_number - 1 ))" "${CONF}.bak" > "$CONF"
    printf '%s\n' "ForwardToSyslog=no" >> "$CONF"
    tail -n "+$(( line_number ))" "${CONF}.bak" >> "$CONF"
fi

rm -f "${CONF}.bak"

echo "[+] Remediation complete: ForwardToSyslog=no is now configured in $CONF"
