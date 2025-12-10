#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_unauthorized_world_writable"

run() {
    local FILTER_NODEV
    local PARTITIONS
    local FOUND_FILES=()

    # Determine nodev filesystems to ignore
    FILTER_NODEV=$(awk '/nodev/ {print $2}' /proc/filesystems | paste -sd, 2>/dev/null)

    # Determine partitions relevant for scanning
    PARTITIONS=$(findmnt -n -l -k -it "$FILTER_NODEV" | awk '{print $1}' | grep -v "/sysroot" 2>/dev/null)

    # Search for world-writable files (-perm -002)
    for PART in $PARTITIONS; do
        [[ -d "$PART" ]] || continue
        mapfile -t tmp < <(find "$PART" -xdev -type f -perm -002 2>/dev/null)
        FOUND_FILES+=("${tmp[@]}")
    done

    # Check /tmp if tmpfs
    if grep -q "^tmpfs /tmp" /proc/mounts; then
        mapfile -t tmp < <(find /tmp -xdev -type f -perm -002 2>/dev/null)
        FOUND_FILES+=("${tmp[@]}")
    fi

    # If no results → OK
    if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|No unauthorized world-writable files found"
        return 0
    fi

    # Build single-line message for SCAP (required)
    file_list=$(printf "%s " "${FOUND_FILES[@]}")

    echo "FAIL|$RULE_ID|Unauthorized world-writable files: $file_list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi