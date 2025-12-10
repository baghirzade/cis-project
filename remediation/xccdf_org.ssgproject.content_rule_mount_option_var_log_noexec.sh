#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_noexec"

echo "[*] Remediating: $RULE_ID"

# Skip container environments
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container detected → skipping remediation"
    exit 0
fi

MP="/var/log"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure /var/log exists in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] $MP not found in /etc/fstab → cannot remediate"
    exit 1
fi

apply_fix() {

    # Add noexec if not present
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw noexec; then
        old_opts=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${old_opts}\)|\1,noexec|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount filesystem
    if mountpoint -q "$MP"; then
        mount -o remount,noexec "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete: $RULE_ID"
