#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_minlen"

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
    print_result "WARN" "/etc/security/pwquality.conf does not exist; minlen is not configured"
    exit 0
fi

# 3) Extract minlen value
minlen_val="$(
    awk -F= '
        /^[[:space:]]*minlen[[:space:]]*=/ {
            v=$2
            gsub(/[[:space:]]/, "", v)
            print v
            exit
        }
    ' "$PWQ_CONF"
)"

if [ -z "${minlen_val}" ]; then
    print_result "WARN" "minlen is not set in /etc/security/pwquality.conf"
    exit 0
fi

# 4) Check numeric and >= 14
if ! printf '%s\n' "$minlen_val" | grep -Eq '^[0-9]+$'; then
    print_result "WARN" "minlen has a non-numeric value '${minlen_val}' in /etc/security/pwquality.conf (expected >= 14)"
    exit 0
fi

if [ "$minlen_val" -ge 14 ]; then
    print_result "OK" "minlen is set to ${minlen_val} in /etc/security/pwquality.conf (meets minimum length requirement of 14)"
else
    print_result "WARN" "minlen is set to ${minlen_val} in /etc/security/pwquality.conf (expected at least 14)"
fi
