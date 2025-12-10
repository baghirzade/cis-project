#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_journald_compress"
JOURNALD_CONF="/etc/systemd/journald.conf"

echo "[*] Applying remediation for: $RULE_ID (configure systemd-journald to compress journals)"

# Ensure dpkg exists (Debian/Ubuntu only)
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicable only if linux-base is installed (same gating as original SCAP logic)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Original CAC logic: only when rsyslog is NOT active (journald is primary logger)
if systemctl is-active rsyslog >/dev/null 2>&1; then
    echo "[!] rsyslog service is active. This remediation is intended for journald-only environments. Skipping."
    exit 0
fi

# Ensure journald.conf exists
if [ ! -f "$JOURNALD_CONF" ]; then
    echo "[*] $JOURNALD_CONF not found, creating it."
    touch "$JOURNALD_CONF"
fi

# Make sure file has a newline at the end
# (some tooling expects this; mirrors CAC behaviour)
sed -i -e '$a\' "$JOURNALD_CONF"

# Backup before changing
cp "$JOURNALD_CONF" "${JOURNALD_CONF}.bak"

# Remove any existing active Compress= lines (non-commented)
# so we can enforce a single clean Compress=yes
sed -i '/^[[:space:]]*Compress[[:space:]]*=/d' "$JOURNALD_CONF"

# If there is a commented Compress line, we don't strictly need to align to it;
# just append our setting at the end for clarity.
echo "Compress=yes" >> "$JOURNALD_CONF"

echo "[+] Remediation applied: Compress=yes has been set in $JOURNALD_CONF"
echo "[+] A backup of the previous configuration was saved at ${JOURNALD_CONF}.bak"

