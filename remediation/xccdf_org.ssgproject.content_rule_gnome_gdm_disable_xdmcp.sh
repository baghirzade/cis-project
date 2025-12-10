#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_gnome_gdm_disable_xdmcp"
CONFIG_DIR="/etc/gdm3"
CONFIG_FILE="/etc/gdm3/custom.conf"

echo "[*] Applying remediation for: $RULE_ID (disable XDMCP in GDM)"

# Ensure dpkg exists
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicable only if gdm3 is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'gdm3' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] gdm3 is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Ensure config directory exists
if [ ! -d "$CONFIG_DIR" ]; then
    echo "[!] Config directory '$CONFIG_DIR' does not exist, not remediating. Assuming non-applicability."
    exit 0
fi

# Ensure config file exists
if [ ! -f "$CONFIG_FILE" ]; then
    touch "$CONFIG_FILE"
fi

# If [xdmcp] section exists and contains an Enable line, force it to false
if grep -q "^\s*\[xdmcp\]\s*$" "$CONFIG_FILE"; then
    if sed -n "/^\s*\[xdmcp\]\s*$/,/^\s*\[/{/^\s*Enable\s*=/p}" "$CONFIG_FILE" | grep -q "Enable"; then
        echo "[*] Updating existing Enable= line under [xdmcp] to Enable=false"
        sed -i '/^\s*\[xdmcp\]\s*$/,/^\s*\[/{s/^\s*Enable\s*=.*/Enable=false/}' "$CONFIG_FILE"
    else
        echo "[*] Adding Enable=false under existing [xdmcp] section"
        sed -i '/^\s*\[xdmcp\]\s*$/a Enable=false' "$CONFIG_FILE"
    fi
else
    echo "[*] Adding new [xdmcp] section with Enable=false"
    {
        echo
        echo "[xdmcp]"
        echo "Enable=false"
    } >> "$CONFIG_FILE"
fi

echo "[+] Remediation complete: XDMCP should now be disabled in $CONFIG_FILE (Enable=false under [xdmcp])."
