#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_rsyslog_filecreatemode"

echo "[*] Applying remediation for: $RULE_ID (configure rsyslog \$FileCreateMode 0640)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicable only if linux-base is installed (per SCAP logic)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base package is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# rsyslog service must be active
if ! command -v systemctl >/dev/null 2>&1; then
    echo "[!] systemctl not found; cannot safely manage rsyslog service. Skipping remediation."
    exit 0
fi

if ! systemctl is-active rsyslog >/dev/null 2>&1; then
    echo "[!] rsyslog service is not active. Remediation is not applicable. No changes applied."
    exit 0
fi

RSYSLOG_CONF="/etc/rsyslog.conf"
RSYSLOG_D="/etc/rsyslog.d"
DROPIN_CONF="$RSYSLOG_D/00-rsyslog_filecreatemode.conf"

# Ensure rsyslog.d directory exists
mkdir -p "$RSYSLOG_D"

echo "[*] Cleaning existing \$FileCreateMode directives in rsyslog drop-in configs (except $DROPIN_CONF)"

# Remove explicit $FileCreateMode lines from other drop-in files
shopt -s nullglob
for f in "$RSYSLOG_D"/*.conf; do
    # Skip our managed file (we will rewrite it below)
    if [ "$f" = "$DROPIN_CONF" ]; then
        continue
    fi
    # Delete lines that set $FileCreateMode to any 4-digit mode
    sed -i -E '/^[[:space:]]*\$FileCreateMode[[:space:]]+[0-9]{4}[[:space:]]*$/d' "$f" || true
done
shopt -u nullglob

# Comment out any $FileCreateMode directives in /etc/rsyslog.conf
if [ -f "$RSYSLOG_CONF" ]; then
    if grep -Eq '^[[:space:]]*\$FileCreateMode[[:space:]]+[0-9]{4}' "$RSYSLOG_CONF"; then
        echo "[*] Commenting existing \$FileCreateMode directives in $RSYSLOG_CONF"
        sed -i -E 's/^([[:space:]]*)(\$FileCreateMode[[:space:]]+[0-9]{4})/\1#\2/' "$RSYSLOG_CONF" || true
    fi
else
    echo "[*] $RSYSLOG_CONF does not exist; relying on drop-in configuration in $RSYSLOG_D"
fi

echo "[*] Ensuring \$FileCreateMode 0640 is configured in $DROPIN_CONF"

# Write the authoritative FileCreateMode setting
{
    echo "# Managed by CIS remediation for $RULE_ID"
    echo "\$FileCreateMode 0640"
} > "$DROPIN_CONF"

# Basic permissions (world-readable is fine for rsyslog config)
chmod 0644 "$DROPIN_CONF"

echo "[*] Restarting rsyslog.service to apply new configuration"
systemctl restart rsyslog.service

echo "[+] Remediation complete: rsyslog is configured to create log files with mode 0640 via \$FileCreateMode."
