#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_warn_age_login_defs"
REQUIRED_DAYS=7
LOGIN_DEFS="/etc/login.defs"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# If 'login' package is not installed, treat as NOTAPPL
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "'login' package is not installed (control not applicable)"
    exit 0
fi

if [ ! -r "$LOGIN_DEFS" ]; then
    print_result "FAIL" "${LOGIN_DEFS} is not readable"
    exit 1
fi

# Get PASS_WARN_AGE value from non-comment lines
value="$(awk '
    $1 !~ /^#/ && $1 == "PASS_WARN_AGE" { v=$2; found=1 }
    END {
        if (found) print v;
    }
' "$LOGIN_DEFS" || true)"

if [ -z "${value:-}" ]; then
    print_result "WARN" "PASS_WARN_AGE is not set in ${LOGIN_DEFS}"
    exit 0
fi

# Must be an integer
if ! [[ "$value" =~ ^[0-9]+$ ]]; then
    print_result "WARN" "PASS_WARN_AGE value '${value}' in ${LOGIN_DEFS} is not a valid integer"
    exit 0
fi

if [ "$value" -lt "$REQUIRED_DAYS" ]; then
    print_result "WARN" "PASS_WARN_AGE is set to ${value} days (< ${REQUIRED_DAYS}) in ${LOGIN_DEFS}"
    exit 0
fi

print_result "OK" "PASS_WARN_AGE is set to ${value} days (>= ${REQUIRED_DAYS}) in ${LOGIN_DEFS}"
exit 0
