#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_nodev"

echo "[*] Remediating: $RULE_ID"

# Skip for containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment → skipping remediation"
    exit 0
fi

MP="/var/log"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure mount point exists in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] $MP entry not found in /etc/fstab → cannot remediate"
    exit 1
fi

apply_fix() {

    # Add nodev if missing
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nodev; then
        old_opts=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${old_opts}\)|\1,nodev|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount
    if mountpoint -q "$MP"; then
        mount -o remount,nodev "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation completed: $RULE_ID"
