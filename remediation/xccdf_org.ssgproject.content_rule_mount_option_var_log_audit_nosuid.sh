#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_var_log_audit_nosuid"

echo "[*] Remediating: $RULE_ID"

# Skip inside containers
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Container environment detected → skipping remediation"
    exit 0
fi

MP="/var/log/audit"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

# Ensure fstab contains this mount point
if ! grep -qE "$REGEX" "$FSTAB"; then
    echo "[-] $MP is not present in /etc/fstab → cannot remediate automatically"
    exit 1
fi

apply_fix() {

    # Add nosuid if missing
    if ! grep -E "$REGEX" "$FSTAB" | grep -qw nosuid; then
        existing=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
        sed -i "s|\(${MP}.*${existing}\)|\1,nosuid|" "$FSTAB"
    fi

    mkdir -p "$MP"

    # Remount with nosuid
    if mountpoint -q "$MP"; then
        mount -o remount,nosuid "$MP"
    else
        mount "$MP"
    fi
}

apply_fix

echo "[+] Remediation complete for: $RULE_ID"
