#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_tmp_nosuid"

echo "[*] Remediating: $RULE_ID"

# Container mühitində tətbiq edilmir
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Not applicable inside container. Skipping."
    exit 0
fi

MP="/tmp"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# /tmp fstab-da olmalıdır
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] /tmp entry not found in /etc/fstab → cannot remediate automatically"
    exit 1
fi

apply_fix() {

    # Əgər nosuid yoxdur → əlavə et
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nosuid; then
        existing=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${existing}\)|\1,nosuid|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount
    if mountpoint -q "$MP"; then
        mount -o remount,nosuid "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete for: $RULE_ID"
