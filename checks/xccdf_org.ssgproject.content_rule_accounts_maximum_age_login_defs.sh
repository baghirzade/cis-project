#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_maximum_age_login_defs"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

LOGIN_DEFS="/etc/login.defs"

# If file is not readable, treat as FAIL (environment/problem)
if [ ! -r "$LOGIN_DEFS" ]; then
    print_result "FAIL" "/etc/login.defs is not readable"
    exit 1
fi

# Get last PASS_MAX_DAYS value (in case of multiple definitions)
current_value="$(awk 'toupper($1)=="PASS_MAX_DAYS" {v=$2} END{print v}' "$LOGIN_DEFS")"

if [ -z "${current_value}" ]; then
    print_result "WARN" "PASS_MAX_DAYS is not set in /etc/login.defs (maximum password age is undefined)"
    exit 0
fi

# Must be an integer
if ! [[ "${current_value}" =~ ^[0-9]+$ ]]; then
    print_result "FAIL" "PASS_MAX_DAYS is not a valid integer: '${current_value}'"
    exit 1
fi

value="${current_value}"

if [ "$value" -gt 0 ] && [ "$value" -le 365 ]; then
    print_result "OK" "PASS_MAX_DAYS is set to ${value} days (within 1–365 as required)"
else
    print_result "WARN" "PASS_MAX_DAYS is set to ${value} days (should be between 1 and 365)"
fi
