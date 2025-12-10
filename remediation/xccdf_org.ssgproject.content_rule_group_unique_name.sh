#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_group_unique_name"
(>&2 echo "Remediating: ${RULE_ID}")

GROUP_FILE="/etc/group"

if [ ! -f "$GROUP_FILE" ]; then
    (>&2 echo "Cannot remediate: $GROUP_FILE does not exist")
    exit 1
fi

# Find duplicate group names
mapfile -t dup_names < <(cut -d: -f1 "$GROUP_FILE" | sort | uniq -d || true)

if [ "${#dup_names[@]}" -eq 0 ]; then
    (>&2 echo "No duplicate group names found; nothing to remediate")
    exit 0
fi

(>&2 echo "Duplicate group names detected. Automatic remediation is intentionally NOT performed because renaming groups can break permissions and services.")
(>&2 echo "Summary of duplicates:")

for name in "${dup_names[@]}"; do
    mapfile -t gids_for_name < <(awk -F: -v n="$name" '$1 == n {print $3}' "$GROUP_FILE")
    if [ "${#gids_for_name[@]}" -gt 0 ]; then
        (>&2 echo "  group '${name}': GIDs ${gids_for_name[*]}")
    fi
done

(>&2 echo)
(>&2 echo "Recommended manual steps:")
(>&2 echo "  1) Decide which group entry should keep each duplicated name.")
(>&2 echo "  2) For the other entries, choose a new unique group name and/or GID (e.g. 'groupmod -n NEWNAME [-g NEWGID] OLDNAME').")
(>&2 echo "  3) Adjust file group ownerships where necessary (e.g. 'find / -group OLDNAME -exec chgrp NEWNAME {} +' or by GID).")
(>&2 echo "  4) Verify that services and access control still work as expected after changes.")

exit 0
