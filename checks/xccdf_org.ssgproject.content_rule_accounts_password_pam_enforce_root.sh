#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_enforce_root"

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

# 2) Config file exists?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "/etc/security/pwquality.conf does not exist; enforce_for_root is not configured"
    exit 0
fi

# 3) Look for enforce_for_root (with or without value)
if grep -Ei '^[[:space:]]*enforce_for_root([[:space:]]*(=|$))' "$PWQ_CONF" >/dev/null 2>&1; then
    print_result "OK" "enforce_for_root is configured in /etc/security/pwquality.conf (root is subject to password quality checks)"
else
    print_result "WARN" "enforce_for_root is not set in /etc/security/pwquality.conf"
fi
