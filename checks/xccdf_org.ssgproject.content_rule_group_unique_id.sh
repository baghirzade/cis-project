#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_group_unique_id"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

GROUP_FILE="/etc/group"

# 1) /etc/group exists?
if [ ! -f "$GROUP_FILE" ]; then
    print_result "FAIL" "$GROUP_FILE is missing; cannot verify GID uniqueness"
    exit 1
fi

# 2) Find duplicated GIDs
mapfile -t dup_gids < <(cut -d: -f3 "$GROUP_FILE" | sort -n | uniq -d || true)

if [ "${#dup_gids[@]}" -eq 0 ]; then
    print_result "OK" "All group IDs in $GROUP_FILE are unique"
    exit 0
fi

# 3) For each duplicated GID, collect groups
details=()
for gid in "${dup_gids[@]}"; do
    mapfile -t groups_for_gid < <(awk -F: -v id="$gid" '$3 == id {print $1}' "$GROUP_FILE")
    if [ "${#groups_for_gid[@]}" -gt 0 ]; then
        details+=( "GID ${gid}: $(IFS=, ; echo "${groups_for_gid[*]}")" )
    fi
done

msg="Duplicate GIDs detected -> ${details[*]}"
print_result "WARN" "$msg"
