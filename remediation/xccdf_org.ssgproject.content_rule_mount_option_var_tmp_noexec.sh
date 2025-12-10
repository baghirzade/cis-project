#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_tmp_noexec"

echo "[*] Remediating: $RULE_ID"

# Skip for containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → skipping remediation."
    exit 0
fi

MP="/var/tmp"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Entry must exist in fstab
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] /var/tmp missing in /etc/fstab → cannot safely remediate."
    exit 1
fi

apply_fix() {

    # Add noexec if missing
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw noexec; then
        old_opts=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${old_opts}\)|\1,noexec|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount
    if mountpoint -q "$MP"; then
        mount -o remount,noexec "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete: $RULE_ID"
