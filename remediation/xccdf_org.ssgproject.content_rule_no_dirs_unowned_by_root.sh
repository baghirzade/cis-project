#!/bin/bash
# REMEDIATION: xccdf_org.ssgproject.content_rule_no_dirs_unowned_by_root
# Fix: Ensure root PATH directories are owned by root:root

if [ "$(id -u)" -ne 0 ]; then
    echo "This remediation must be run as root!" >&2
    exit 1
fi

PATH_TO_FIX="${PATH}"
IFS=':' read -ra PATH_DIRS <<< "$PATH_TO_FIX"

for dir in "${PATH_DIRS[@]}"; do
    [ -z "$dir" ] && continue

    if [[ "$dir" != /* ]]; then
        echo "Skipping non-absolute PATH entry '$dir'."
        continue
    fi

    if [ ! -d "$dir" ]; then
        echo "Skipping '$dir' (not a valid directory)."
        continue
    fi

    owner_uid=$(stat -c "%u" "$dir" 2>/dev/null)
    owner_gid=$(stat -c "%g" "$dir" 2>/dev/null)

    if [ "$owner_uid" -ne 0 ] || [ "$owner_gid" -ne 0 ]; then
        echo "Fixing ownership: chown root:root '$dir'"
        chown root:root "$dir"
    else
        echo "OK: '$dir' already root-owned."
    fi
done

echo "Remediation completed."
