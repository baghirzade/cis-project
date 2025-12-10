#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_group_unique_name"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

GROUP_FILE="/etc/group"

# 1) /etc/group exists?
if [ ! -f "$GROUP_FILE" ]; then
    print_result "FAIL" "$GROUP_FILE is missing; cannot verify group name uniqueness"
    exit 1
fi

# 2) Find duplicated group names (first field)
mapfile -t dup_names < <(cut -d: -f1 "$GROUP_FILE" | sort | uniq -d || true)

if [ "${#dup_names[@]}" -eq 0 ]; then
    print_result "OK" "All group names in $GROUP_FILE are unique"
    exit 0
fi

# 3) For each duplicate name, list associated GIDs
details=()
for name in "${dup_names[@]}"; do
    mapfile -t gids_for_name < <(awk -F: -v n="$name" '$1 == n {print $3}' "$GROUP_FILE")
    if [ "${#gids_for_name[@]}" -gt 0 ]; then
        details+=( "group '${name}' (GIDs: $(IFS=, ; echo "${gids_for_name[*]}"))" )
    fi
done

msg="Duplicate group names detected -> ${details[*]}"
print_result "WARN" "$msg"
