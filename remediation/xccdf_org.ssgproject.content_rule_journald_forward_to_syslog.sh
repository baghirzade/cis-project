#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_journald_forward_to_syslog"
JOURNALD_CONF="/etc/systemd/journald.conf"

echo "[*] Applying remediation for: $RULE_ID (ensure ForwardToSyslog=yes when rsyslog is active)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Remediation is applicable only if linux-base is installed and rsyslog is active
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation not applicable. No changes applied."
    exit 0
fi

if ! systemctl is-active rsyslog &>/dev/null; then
    echo "[!] rsyslog service is not active. Remediation not applicable. No changes applied."
    exit 0
fi

echo "[*] linux-base installed and rsyslog active; enforcing ForwardToSyslog=yes in $JOURNALD_CONF"

# Ensure journald.conf exists
if [ -e "$JOURNALD_CONF" ] ; then
    # Remove any existing ForwardToSyslog= lines
    LC_ALL=C sed -i "/^\s*ForwardToSyslog\s*=\s*/d" "$JOURNALD_CONF"
else
    touch "$JOURNALD_CONF"
fi

# Make sure file has newline at the end
sed -i -e '$a\' "$JOURNALD_CONF"

# Work on a backup to insert the directive in a clean way
cp "$JOURNALD_CONF" "${JOURNALD_CONF}.bak"

# Insert before the line matching the regex '^#\s*ForwardToSyslog'.
line_number="$(LC_ALL=C grep -n "^#\s*ForwardToSyslog" "${JOURNALD_CONF}.bak" | LC_ALL=C sed 's/:.*//g')"
if [ -z "$line_number" ]; then
    # There was no match of '^#\s*ForwardToSyslog', append at the end of the file.
    printf '%s\n' "ForwardToSyslog=yes" >> "$JOURNALD_CONF"
else
    head -n "$(( line_number - 1 ))" "${JOURNALD_CONF}.bak" > "$JOURNALD_CONF"
    printf '%s\n' "ForwardToSyslog=yes" >> "$JOURNALD_CONF"
    tail -n "+$(( line_number ))" "${JOURNALD_CONF}.bak" >> "$JOURNALD_CONF"
fi

# Clean up after ourselves.
rm -f "${JOURNALD_CONF}.bak"

echo "[+] Remediation complete: ForwardToSyslog=yes is configured in $JOURNALD_CONF while rsyslog is active."
