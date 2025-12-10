#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_password_hashing_algorithm_logindefs"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

LOGIN_DEFS="/etc/login.defs"

# 1) 'login' package installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "login package is not installed (control not applicable)"
    exit 0
fi

# 2) Config file exists?
if [ ! -f "$LOGIN_DEFS" ]; then
    print_result "WARN" "$LOGIN_DEFS does not exist; ENCRYPT_METHOD is not configured"
    exit 0
fi

# 3) Read ENCRYPT_METHOD line
encrypt_line=$(grep -Ei '^[[:space:]]*ENCRYPT_METHOD[[:space:]]+' "$LOGIN_DEFS" | head -n 1 || true)

if [ -z "$encrypt_line" ]; then
    print_result "WARN" "ENCRYPT_METHOD is not configured in $LOGIN_DEFS"
    exit 0
fi

algo=$(echo "$encrypt_line" | awk '{print $2}')

if [ -z "$algo" ]; then
    print_result "WARN" "ENCRYPT_METHOD is present but has no value in $LOGIN_DEFS"
    exit 0
fi

case "$algo" in
    SHA512|YESCRYPT)
        print_result "OK" "Password hashing algorithm in $LOGIN_DEFS is '$algo'"
        ;;
    *)
        print_result "WARN" "Password hashing algorithm in $LOGIN_DEFS is '$algo' (expected SHA512 or YESCRYPT)"
        ;;
esac
