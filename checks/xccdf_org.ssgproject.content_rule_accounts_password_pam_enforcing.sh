#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_enforcing"

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
    print_result "WARN" "/etc/security/pwquality.conf does not exist; enforcing is not configured"
    exit 0
fi

# 3) Extract enforcing value if present
enforcing_val="$(
    awk -F= '
        /^[[:space:]]*enforcing[[:space:]]*=/ {
            v=$2
            gsub(/[[:space:]]/, "", v)
            print v
            exit
        }
    ' "$PWQ_CONF"
)"

if [ -z "${enforcing_val}" ]; then
    print_result "WARN" "enforcing is not set in /etc/security/pwquality.conf"
    exit 0
fi

if [ "$enforcing_val" = "1" ]; then
    print_result "OK" "enforcing is set to 1 in /etc/security/pwquality.conf (weak passwords are rejected)"
else
    print_result "WARN" "enforcing is set to '${enforcing_val}' in /etc/security/pwquality.conf (expected 1)"
fi
