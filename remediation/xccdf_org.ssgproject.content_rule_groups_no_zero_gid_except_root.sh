#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_groups_no_zero_gid_except_root"

# Find groups that have GID 0 but are not 'root'
mapfile -t bad_groups < <(awk -F: '$3 == 0 && $1 != "root" { print $1 }' /etc/group)

# Nothing to do if there are no offending groups
if [ "${#bad_groups[@]}" -eq 0 ]; then
    exit 0
fi

# Helper: find next free GID (starting from 1000 to avoid system GIDs)
get_next_gid() {
    awk -F: '
        BEGIN { min=1000; max=min }
        {
            if ($3 >= min && $3 >= max) {
                max = $3 + 1
            }
        }
        END { print max }
    ' /etc/group
}

for grp in "${bad_groups[@]}"; do
    new_gid="$(get_next_gid)"

    if getent group "${new_gid}" >/dev/null 2>&1; then
        # In the unlikely case it is already used, bump until free
        while getent group "${new_gid}" >/dev/null 2>&1; do
            new_gid=$(( new_gid + 1 ))
        done
    fi

    if groupmod -g "${new_gid}" "${grp}"; then
        >&2 echo "Changed GID for group '${grp}' from 0 to ${new_gid}"
    else
        >&2 echo "Failed to change GID for group '${grp}'"
        exit 1
    fi
done

exit 0
