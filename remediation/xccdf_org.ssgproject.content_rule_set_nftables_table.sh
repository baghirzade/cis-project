#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_nftables_table"

echo "[*] Applying remediation for: $RULE_ID (Create nftables base table)"

# Remediation is applicable only if nftables package is installed
if dpkg-query --show --showformat='${db:Status-Status}' 'nftables' 2>/dev/null | grep -q '^installed$'; then

var_nftables_family='inet'
var_nftables_table='filter'

echo "[*] Checking for existence of table: $var_nftables_family $var_nftables_table"

# Use 'nft list table' which fails if the table doesn't exist.
if ! nft list table "$var_nftables_family" "$var_nftables_table" &>/dev/null; then
    echo "    -> Table not found. Creating table: $var_nftables_family $var_nftables_table"
    if nft create table "$var_nftables_family" "$var_nftables_table"; then
        echo "[+] Remediation complete: Table created successfully."
    else
        echo "[!] ERROR: Failed to create nftables table. Check nftables status."
        exit 1
    fi
else
    echo "[+] Table already exists. No action needed."
fi

else
    >&2 echo 'Remediation is not applicable, nftables package is not installed.'
fi
