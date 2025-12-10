#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nodev"

echo "[*] Remediating: $RULE_ID"

# Container mühitində işləməsin
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Remediation not applicable in containers."
    exit 0
fi

MOUNT_POINT="/dev/shm"
FSTAB="/etc/fstab"
REGEXP="^[[:space:]]*[^#].*[[:space:]]${MOUNT_POINT}[[:space:]]"

ensure_nodev() {

    # /dev/shm fstab-da varmı?
    if ! grep -qE "$REGEXP" "$FSTAB"; then
        # mtab-dan əvvəlki mount opsiyaları götür
        prev=$(grep -E "$REGEXP" /etc/mtab | head -1 | awk '{print $4}' \
               | sed -E "s/(rw|defaults|seclabel|nodev)(,|$)//g;s/,$//")

        [[ -n "$prev" ]] && prev="${prev},"

        # Yeni sətir əlavə et
        echo "tmpfs /dev/shm tmpfs defaults,${prev}nodev 0 0" >> "$FSTAB"

    else
        # fstab daxilində nodev yoxdursa əlavə et
        if ! grep -E "$REGEXP" "$FSTAB" | grep -qw nodev; then
            prev=$(grep -E "$REGEXP" "$FSTAB" | awk '{print $4}')
            sed -i "s|\(${MOUNT_POINT}.*${prev}\)|\1,nodev|" "$FSTAB"




cat << 'EOF' > remediation/xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nodev.sh
#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_mount_option_dev_shm_nodev"

echo "[*] Remediating: $RULE_ID"

# Container mühitində işləməsin
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
    echo "[*] Remediation not applicable in containers."
    exit 0
fi

MOUNT_POINT="/dev/shm"
FSTAB="/etc/fstab"
REGEXP="^[[:space:]]*[^#].*[[:space:]]${MOUNT_POINT}[[:space:]]"

ensure_nodev() {

    # /dev/shm fstab-da varmı?
    if ! grep -qE "$REGEXP" "$FSTAB"; then
        # mtab-dan əvvəlki mount opsiyaları götür
        prev=$(grep -E "$REGEXP" /etc/mtab | head -1 | awk '{print $4}' \
               | sed -E "s/(rw|defaults|seclabel|nodev)(,|$)//g;s/,$//")

        [[ -n "$prev" ]] && prev="${prev},"

        # Yeni sətir əlavə et
        echo "tmpfs /dev/shm tmpfs defaults,${prev}nodev 0 0" >> "$FSTAB"

    else
        # fstab daxilində nodev yoxdursa əlavə et
        if ! grep -E "$REGEXP" "$FSTAB" | grep -qw nodev; then
            prev=$(grep -E "$REGEXP" "$FSTAB" | awk '{print $4}')
            sed -i "s|\(${MOUNT_POINT}.*${prev}\)|\1,nodev|" "$FSTAB"
        fi
    fi

    mkdir -p "$MOUNT_POINT"

    # Remount
    if mountpoint -q "$MOUNT_POINT"; then
        mount -o remount,nodev "$MOUNT_POINT"
    else
        mount "$MOUNT_POINT"
    fi
}

ensure_nodev

echo "[+] Remediation complete for: $RULE_ID"
