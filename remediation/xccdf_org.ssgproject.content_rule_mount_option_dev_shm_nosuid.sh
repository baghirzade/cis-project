#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nosuid"

echo "[*] Remediating: $RULE_ID"

# Container mühitində tətbiq edilmir
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Not applicable inside container. Skipping."
    exit 0
fi

MP="/dev/shm"
FSTAB="/etc/fstab"
REGEX="^[[:space:]]*[^#].*[[:space:]]${MP}[[:space:]]"

apply_fix() {

    # fstab-da qeyd olunubmu?
    if ! grep -qE "$REGEX" "$FSTAB"; then
    
        # runtime mount opsiyalarını götür
        prev=$(grep -E "$REGEX" /etc/mtab | head -1 | awk '{print $4}' \
               | sed -E "s/(rw|defaults|seclabel|nosuid)(,|$)//g;s/,$//")

        [[ -n "$prev" ]] && prev="${prev},"

        echo "tmpfs /dev/shm tmpfs defaults,${prev}nosuid 0 0" >> "$FSTAB"

    else
        
        # nosuid yoxdursa əlavə et
        if ! grep -E "$REGEX" "$FSTAB" | grep -qw nosuid; then
            existing=$(grep -E "$REGEX" "$FSTAB" | awk '{print $4}')
            sed -i "s|\(${MP}.*${existing}\)|\1,nosuid|" "$FSTAB"
        fi
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
