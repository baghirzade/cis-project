#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_nosuid"

echo "[*] Remediating: $RULE_ID"

# Skip inside containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → skipping."
    exit 0
fi

MP="/var/log"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure mount point exists in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] $MP missing from /etc/fstab → cannot remediate"
    exit 1
fi

apply_fix() {

    # Add nosuid if absent
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nosuid; then
        old_opts=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${old_opts}\)|\1,nosuid|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount filesystem
    if mountpoint -q "$MP"; then
        mount -o remount,nosuid "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete: $RULE_ID"
