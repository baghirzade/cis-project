#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_postfix_network_listening_disabled"

echo "[*] Applying remediation for: $RULE_ID"

# Applicability check
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] dpkg not found, skipping."
    exit 0
fi

if ! dpkg -s postfix >/dev/null 2>&1; then
    echo "[!] Postfix not installed, skipping."
    exit 0
fi

CFG="/etc/postfix/main.cf"
var_postfix_inet_interfaces="loopback-only"

# Ensure config file exists
touch "$CFG"

# Remove any existing inet_interfaces entries
sed -i "/^\s*inet_interfaces\s*=/Id" "$CFG"

# Ensure newline at EOF
sed -i -e '$a\' "$CFG"

# Append correct setting
printf '%s\n' "inet_interfaces=$var_postfix_inet_interfaces" >> "$CFG"

# Restart postfix safely
if command -v systemctl >/dev/null 2>&1; then
    systemctl restart postfix || true
fi

echo "[+] Remediation complete: Postfix now listens only on loopback."
