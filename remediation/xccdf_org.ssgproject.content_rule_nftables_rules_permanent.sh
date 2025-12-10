#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_nftables_rules_permanent"

echo "[*] Applying remediation for: $RULE_ID"

# nftables must be installed and firewalld must be inactive
if ! dpkg-query --show --showformat='${db:Status-Status}' nftables \
    2>/dev/null | grep -q '^installed$'; then
    echo "[!] nftables not installed — remediation not applicable"
    exit 0
fi

if systemctl is-active firewalld &>/dev/null; then
    echo "[!] firewalld is active — nftables permanent rules not applicable"
    exit 0
fi

MASTER_FILE="/etc/nftables.conf"
FAMILY="inet"
RULEFILE="/etc/${FAMILY}-filter.rules"

# Ensure master config exists
if [[ ! -f "$MASTER_FILE" ]]; then
    echo "[*] Creating $MASTER_FILE"
    touch "$MASTER_FILE"
fi

echo "[*] Exporting current nftables ruleset into $RULEFILE"
nft list ruleset > "$RULEFILE"

# Ensure include line is present
INCLUDE_LINE="include \"/etc/${FAMILY}-filter.rules\""

if ! grep -qxF "$INCLUDE_LINE" "$MASTER_FILE"; then
    echo "[*] Adding include directive to $MASTER_FILE"
    echo "$INCLUDE_LINE" >> "$MASTER_FILE"
fi

echo "[+] Remediation complete: nftables permanent rules configured"
