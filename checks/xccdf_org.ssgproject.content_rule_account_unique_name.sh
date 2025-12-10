#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_account_unique_name"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

PASSWD_FILE="/etc/passwd"

if [ ! -r "$PASSWD_FILE" ]; then
    print_result "FAIL" "$PASSWD_FILE is not readable"
    exit 1
fi

# Find duplicate usernames (first field in /etc/passwd)
duplicates="$(awk -F: '{print $1}' "$PASSWD_FILE" | sort | uniq -d | paste -sd',' -)"

if [ -z "$duplicates" ]; then
    print_result "OK" "All user account names in /etc/passwd are unique"
else
    print_result "WARN" "Duplicate user account names found in /etc/passwd: ${duplicates}"
fi
