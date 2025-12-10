#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_audit_nodev"

echo "[*] Remediating: $RULE_ID"

# Skip if container
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → Skipping"
    exit 0
fi

MP="/var/log/audit"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Must exist in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] $MP is not present in /etc/fstab → cannot remediate automatically"
    exit 1
fi

apply_fix() {

    # Add nodev if missing
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nodev; then
        existing=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${existing}\)|\1,nodev|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount with new flags
    if mountpoint -q "$MP"; then
        mount -o remount,nodev "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete for: $RULE_ID"
