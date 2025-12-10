#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_maxrepeat"

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

# 2) Config file present?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "/etc/security/pwquality.conf does not exist; maxrepeat is not configured"
    exit 0
fi

# 3) Extract maxrepeat value if present
maxrepeat_val="$(
    awk -F= '
        /^[[:space:]]*maxrepeat[[:space:]]*=/ {
            v=$2
            gsub(/[[:space:]]/, "", v)
            print v
            exit
        }
    ' "$PWQ_CONF"
)"

if [ -z "${maxrepeat_val}" ]; then
    print_result "WARN" "maxrepeat is not set in /etc/security/pwquality.conf"
    exit 0
fi

if [ "$maxrepeat_val" = "3" ]; then
    print_result "OK" "maxrepeat is set to 3 in /etc/security/pwquality.conf (maximum 3 consecutive identical characters allowed)"
else
    print_result "WARN" "maxrepeat is set to '${maxrepeat_val}' in /etc/security/pwquality.conf (expected 3)"
fi
