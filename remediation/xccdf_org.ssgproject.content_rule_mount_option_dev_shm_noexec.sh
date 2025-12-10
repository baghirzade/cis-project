#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_noexec"

echo "[*] Remediating: $RULE_ID"

# Container mühitində işləməsin
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Remediation not applicable in container environments."
    exit 0
fi

MOUNT_POINT="/dev/shm"
FSTAB="/etc/fstab"
REGEXP="^[[:space:]]*[^#].*[[:space:]]${MOUNT_POINT}[[:space:]]"

fix_noexec() {

    # /dev/shm fstab-da qeyd olunub?
    if ! grep -qE "$REGEXP" "$FSTAB"; then

        # Mövcud mount opsiyalarını runtime-dan götür
        prev=$(grep -E "$REGEXP" /etc/mtab | head -1 | awk '{print $4}' \
               | sed -E "s/(rw|defaults|seclabel|noexec)(,|$)//g;s/,$//")

        [[ -n "$prev" ]] && prev="${prev},"

        echo "tmpfs /dev/shm tmpfs defaults,${prev}noexec 0 0" >> "$FSTAB"

    else
        # fstab daxilində noexec yoxdursa əlavə et
        if ! grep -E "$REGEXP" "$FSTAB" | grep -qw noexec; then
            prev=$(grep -E "$REGEXP" "$FSTAB" | awk '{print $4}')
            sed -i "s|\(${MOUNT_POINT}.*${prev}\)|\1,noexec|" "$FSTAB"
        fi
    fi

    mkdir -p "$MOUNT_POINT"

    # Remount
    if mountpoint -q "$MOUNT_POINT"; then
        mount -o remount,noexec "$MOUNT_POINT"
    else
        mount "$MOUNT_POINT"
    fi
}

fix_noexec

echo "[+] Remediation complete for: $RULE_ID"
