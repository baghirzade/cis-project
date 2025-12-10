#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_shadow_group_empty"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

GROUP_FILE="/etc/group"

# If group file is not readable, treat as FAIL (script error / environment problem)
if [ ! -r "$GROUP_FILE" ]; then
    print_result "FAIL" "/etc/group is not readable"
    exit 1
fi

shadow_line="$(grep '^shadow:' "$GROUP_FILE" || true)"

# If there is no 'shadow' group line at all
if [ -z "$shadow_line" ]; then
    print_result "WARN" "shadow group entry is missing in /etc/group"
    exit 0
fi

members="$(echo "$shadow_line" | awk -F: '{print $4}')"

if [ -z "$members" ]; then
    print_result "OK" "shadow group has no members (group is empty as required)"
else
    print_result "WARN" "shadow group has members: ${members}"
fi
