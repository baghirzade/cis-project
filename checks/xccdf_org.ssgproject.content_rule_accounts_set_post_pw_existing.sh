#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_set_post_pw_existing"
SHADOW_FILE="/etc/shadow"
REQUIRED_INACTIVE_DAYS=45

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

if [ ! -r "$SHADOW_FILE" ]; then
    print_result "FAIL" "${SHADOW_FILE} is not readable"
    exit 1
fi

# Find accounts with a password hash ($2 starts with '$') and inactive field ($7)
# that is empty or greater than REQUIRED_INACTIVE_DAYS
mapfile -t bad_accounts < <(awk -F: -v var="$REQUIRED_INACTIVE_DAYS" '
    ($2 ~ /^\$/) && (($7 == "") || ($7 > var)) { print $1 }
' "$SHADOW_FILE")

if [ "${#bad_accounts[@]}" -eq 0 ]; then
    print_result "OK" "All applicable accounts have password inactivity set to <= ${REQUIRED_INACTIVE_DAYS} days"
    exit 0
fi

# Join list in a compact way (limit to first few if many)
if [ "${#bad_accounts[@]}" -le 5 ]; then
    list_str="${bad_accounts[*]}"
else
    # show first 5, then count
    first_five=("${bad_accounts[@]:0:5}")
    list_str="${first_five[*]} and $(( ${#bad_accounts[@]} - 5 )) more"
fi

print_result "WARN" "Accounts with inactive period unset or > ${REQUIRED_INACTIVE_DAYS} days: ${list_str}"
exit 0
