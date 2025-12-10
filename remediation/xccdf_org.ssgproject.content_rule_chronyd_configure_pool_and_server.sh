#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_chronyd_configure_pool_and_server"

echo "[*] Applying remediation for: $RULE_ID"

# Applicability checks
if ! command -v dpkg >/dev/null 2>&1; then
    echo "[!] Not a Debian system, skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' linux-base 2>/dev/null \
    | grep -q installed; then
    echo "[!] linux-base not installed, skipping."
    exit 0
fi

if ! dpkg-query --show --showformat='${db:Status-Status}' chrony 2>/dev/null \
    | grep -q installed; then
    echo "[!] chrony not installed, skipping."
    exit 0
fi

config_file="/etc/chrony/chrony.conf"

# Load SCAP variables or defaults
var_multiple_time_servers="${var_multiple_time_servers:-0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org}"
var_multiple_time_pools="${var_multiple_time_pools:-0.ubuntu.pool.ntp.org,1.ubuntu.pool.ntp.org,2.ubuntu.pool.ntp.org,3.ubuntu.pool.ntp.org}"

IFS=',' read -ra SERVERS <<< "$var_multiple_time_servers"
IFS=',' read -ra POOLS <<< "$var_multiple_time_pools"

echo "[*] Ensuring chrony.conf contains required server entries..."

for srv in "${SERVERS[@]}"; do
    if ! grep -Eq "^\s*server\s+$srv(\s|$)" "$config_file"; then
        echo "server $srv" >> "$config_file"
        echo "    Added server $srv"
    fi
done

echo "[*] Ensuring chrony.conf contains required pool entries..."

for srv in "${POOLS[@]}"; do
    if ! grep -Eq "^\s*pool\s+$srv(\s|$)" "$config_file"; then
        echo "pool $srv" >> "$config_file"
        echo "    Added pool $srv"
    fi
done

echo "[+] Remediation complete: chrony server and pool configuration updated."
