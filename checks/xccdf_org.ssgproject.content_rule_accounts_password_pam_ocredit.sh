#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_ocredit"

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
    print_result "WARN" "/etc/security/pwquality.conf does not exist; ocredit is not configured"
    exit 0
fi

# 3) Extract ocredit value (first occurrence)
ocredit_val="$(
    awk -F= '
        /^[[:space:]]*ocredit[[:space:]]*=/ {
            v=$2
            gsub(/[[:space:]]/, "", v)
            print v
            exit
        }
    ' "$PWQ_CONF"
)"

if [ -z "${ocredit_val}" ]; then
    print_result "WARN" "ocredit is not set in /etc/security/pwquality.conf"
    exit 0
fi

# 4) Check numeric and <= -1 (at least one other character required)
if ! printf '%s\n' "$ocredit_val" | grep -Eq '^-?[0-9]+$'; then
    print_result "WARN" "ocredit has a non-numeric value '${ocredit_val}' in /etc/security/pwquality.conf (expected <= -1)"
    exit 0
fi

if [ "$ocredit_val" -le -1 ]; then
    print_result "OK" "ocredit is set to ${ocredit_val} in /etc/security/pwquality.conf (meets requirement: at least one non-alphanumeric character)"
else
    print_result "WARN" "ocredit is set to ${ocredit_val} in /etc/security/pwquality.conf (expected value <= -1 to require at least one non-alphanumeric character)"
fi
