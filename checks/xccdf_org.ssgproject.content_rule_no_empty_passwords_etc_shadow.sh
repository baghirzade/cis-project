#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_empty_passwords_etc_shadow"
SHADOW_FILE="/etc/shadow"

if [[ ! -r "$SHADOW_FILE" ]]; then
    echo "FAIL|${RULE_ID}|Cannot read /etc/shadow"
    exit 0
fi

mapfile -t users_with_empty_pass < <(awk -F: '$2 == "" {print $1}' "$SHADOW_FILE")

if [[ ${#users_with_empty_pass[@]} -eq 0 ]]; then
    echo "OK|${RULE_ID}|All accounts in /etc/shadow have a password hash set (no empty passwords)"
else
    list=$(printf "%s " "${users_with_empty_pass[@]}")
    echo "WARN|${RULE_ID}|Accounts with empty password field in /etc/shadow: ${list}"
fi

exit 0
