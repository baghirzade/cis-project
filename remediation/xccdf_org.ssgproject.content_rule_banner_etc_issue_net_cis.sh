#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_banner_etc_issue_net_cis"

echo "[*] Applying remediation for: $RULE_ID (configure CIS-compliant /etc/issue.net banner)"

BANNER_FILE="/etc/issue.net"
CIS_BANNER_TEXT='Authorized users only. All activity may be monitored and reported.'

# Only Debian/Ubuntu systems have dpkg
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, remediation is only applicable on Debian/Ubuntu. Skipping."
    exit 0
fi

# Applicability: linux-base must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "[!] linux-base is not installed. Remediation is not applicable. No changes applied."
    exit 0
fi

# Backup existing banner if present
if [ -f "$BANNER_FILE" ]; then
    echo "[*] Backing up existing $BANNER_FILE to ${BANNER_FILE}.bak_cis_banner"
    cp "$BANNER_FILE" "${BANNER_FILE}.bak_cis_banner"
fi

# Write CIS banner
echo "[*] Writing CIS-compliant banner to $BANNER_FILE"
printf '%s\n' "$CIS_BANNER_TEXT" > "$BANNER_FILE"

# Set conservative permissions
chmod 644 "$BANNER_FILE"

echo "[+] Remediation complete: $BANNER_FILE now contains the CIS-compliant banner."
