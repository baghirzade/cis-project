#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_account_unique_id"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

PASSWD_FILE="/etc/passwd"

# 1) /etc/passwd mövcuddur?
if [ ! -f "$PASSWD_FILE" ]; then
    print_result "FAIL" "$PASSWD_FILE is missing; cannot verify UID uniqueness"
    exit 1
fi

# 2) Duplicated UIDs tap
mapfile -t dup_uids < <(cut -d: -f3 "$PASSWD_FILE" | sort -n | uniq -d || true)

if [ "${#dup_uids[@]}" -eq 0 ]; then
    print_result "OK" "All user IDs in $PASSWD_FILE are unique"
    exit 0
fi

# 3) Hər duplicated UID üçün user-ləri topla
details=()
for uid in "${dup_uids[@]}"; do
    mapfile -t users_for_uid < <(awk -F: -v id="$uid" '$3 == id {print $1}' "$PASSWD_FILE")
    if [ "${#users_for_uid[@]}" -gt 0 ]; then
        details+=( "UID ${uid}: $(IFS=, ; echo "${users_for_uid[*]}")" )
    fi
done

msg="Duplicate UIDs detected -> ${details[*]}"
print_result "WARN" "$msg"
