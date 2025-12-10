#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_minclass"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpwquality1 installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpwquality1 is not installed (control not applicable)"
    exit 0
fi

PWQ_CONF="/etc/security/pwquality.conf"

# 2) pwquality.conf exists?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "/etc/security/pwquality.conf does not exist; minclass is not configured"
    exit 0
fi

# 3) Extract minclass value
minclass_val="$(
    awk -F= '
        /^[[:space:]]*minclass[[:space:]]*=/ {
            v=$2
            gsub(/[[:space:]]/, "", v)
            print v
            exit
        }
    ' "$PWQ_CONF"
)"

if [ -z "${minclass_val}" ]; then
    print_result "WARN" "minclass is not set in /etc/security/pwquality.conf"
    exit 0
fi

# 4) Check numeric and >= 4
if ! printf '%s\n' "$minclass_val" | grep -Eq '^[0-9]+$'; then
    print_result "WARN" "minclass has a non-numeric value '${minclass_val}' in /etc/security/pwquality.conf (expected >= 4)"
    exit 0
fi

if [ "$minclass_val" -ge 4 ]; then
    print_result "OK" "minclass is set to ${minclass_val} in /etc/security/pwquality.conf (meets minimum requirement of 4 character classes)"
else
    print_result "WARN" "minclass is set to ${minclass_val} in /etc/security/pwquality.conf (expected at least 4)"
fi
