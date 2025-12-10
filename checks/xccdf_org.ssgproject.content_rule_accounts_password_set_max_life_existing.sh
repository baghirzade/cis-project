#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_set_max_life_existing"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

SHADOW_FILE="/etc/shadow"
MAX_DAYS="365"

# Environment / permission problem => FAIL
if [ ! -r "$SHADOW_FILE" ]; then
    print_result "FAIL" "/etc/shadow is not readable"
    exit 1
fi

# Find accounts with password set and max life > MAX_DAYS or unset
mapfile -t bad_users < <(awk -F: -v var="$MAX_DAYS" '
    /^[^:]+:[^!*]/ && ($5 == "" || $5 > var) { print $1 }
' "$SHADOW_FILE")

if [ "${#bad_users[@]}" -eq 0 ]; then
    print_result "OK" "All existing password-enabled accounts have maximum password age <= ${MAX_DAYS} days"
    exit 0
fi

# Join list into a comma-separated string
user_list="$(printf '%s, ' "${bad_users[@]}" | sed 's/, $//')"
print_result "WARN" "Accounts with password max life > ${MAX_DAYS} days or unset: ${user_list}"
exit 0
