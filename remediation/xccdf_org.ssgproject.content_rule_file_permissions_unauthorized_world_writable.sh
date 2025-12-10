#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_unauthorized_world_writable"

echo "[*] Applying remediation for: $RULE_ID (Remove world-writable file permissions)"

FILTER_NODEV=$(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd, || true)

# Do not consider /sysroot partition because it contains only the physical
# read-only root on bootable containers.
PARTITIONS=$(findmnt -n -l -k -it "$FILTER_NODEV" | awk '{ print $1 }' | grep -v "/sysroot" || true)

echo "[*] Processing files on mounted partitions (excluding nodev and /sysroot)..."
for PARTITION in $PARTITIONS; do
    if [ -d "$PARTITION" ]; then
        echo "    -> Searching and fixing files in $PARTITION..."
        # find files (-type f) with world-writable permission (-perm -002) and remove it (chmod o-w)
        # 2>/dev/null suppresses "Permission denied" errors
        find "${PARTITION}" -xdev -type f -perm -002 -exec chmod o-w {} \; 2>/dev/null || true
    fi
done

# Ensure /tmp is also fixed when tmpfs is used.
if grep -q "^tmpfs /tmp" /proc/mounts; then
    echo "[*] Processing files in /tmp (tmpfs)..."
    # find files (-type f) with world-writable permission (-perm -002) and remove it (chmod o-w)
    find /tmp -xdev -type f -perm -002 -exec chmod o-w {} \; 2>/dev/null || true
else
    echo "[*] /tmp is not mounted as tmpfs or not a separate partition. Check handled by general loop."
fi

echo "[+] Remediation complete: World-writable permissions removed from unauthorized files."
