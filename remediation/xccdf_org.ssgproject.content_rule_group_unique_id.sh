#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_group_unique_id"
(>&2 echo "Remediating: ${RULE_ID}")

GROUP_FILE="/etc/group"

if [ ! -f "$GROUP_FILE" ]; then
    (>&2 echo "Cannot remediate: $GROUP_FILE does not exist")
    exit 1
fi

# Find duplicate GIDs
mapfile -t dup_gids < <(cut -d: -f3 "$GROUP_FILE" | sort -n | uniq -d || true)

if [ "${#dup_gids[@]}" -eq 0 ]; then
    (>&2 echo "No duplicate GIDs found; nothing to remediate")
    exit 0
fi

(>&2 echo "Duplicate GIDs detected. Automatic remediation is intentionally NOT performed because changing GIDs can break permissions and services.")
(>&2 echo "Summary of duplicate GIDs:")

for gid in "${dup_gids[@]}"; do
    mapfile -t groups_for_gid < <(awk -F: -v id="$gid" '$3 == id {print $1}' "$GROUP_FILE")
    if [ "${#groups_for_gid[@]}" -gt 0 ]; then
        (>&2 echo "  GID ${gid}: ${groups_for_gid[*]}")
    fi
done

(>&2 echo)
(>&2 echo "Recommended manual steps:")
(>&2 echo "  1) Decide which group should keep each duplicated GID.")
(>&2 echo "  2) For the other groups, assign a new unique GID (e.g. 'groupmod -g NEWGID GROUP').")
(>&2 echo "  3) Adjust file group ownerships if needed (find / -gid OLDGID -exec chgrp NEWGID {} +).")
(>&2 echo "  4) Verify that services and access control still work as expected.")

exit 0
