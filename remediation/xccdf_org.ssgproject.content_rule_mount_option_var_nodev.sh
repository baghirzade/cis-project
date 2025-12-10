#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_nodev"

echo "[*] Remediating: $RULE_ID"

# Do not remediate inside containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → skipping remediation."
    exit 0
fi

MP="/var"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure /var exists in /etc/fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] /var not present in /etc/fstab → cannot safely apply mount options."
    exit 1
fi

apply_fix() {

    # Add "nodev" if missing
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nodev; then
        old_opts=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${old_opts}\)|\1,nodev|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount filesystem
    if mountpoint -q "$MP"; then
        mount -o remount,nodev "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete: $RULE_ID"
