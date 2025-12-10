#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_nosuid"

echo "[*] Remediating: $RULE_ID"

# Skip in containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → skipping remediation."
    exit 0
fi

MP="/var"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure /var exists in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] /var not present in /etc/fstab → cannot safely apply mount options."
    exit 1
fi

apply_fix() {

    # Add nosuid if missing
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
