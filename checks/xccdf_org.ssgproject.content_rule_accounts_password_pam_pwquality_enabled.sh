#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwquality_enabled"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpam-runtime installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

# 2) libpam-pwquality installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-pwquality' 2>/dev/null | grep -q '^installed$'; then
    print_result "WARN" "libpam-pwquality is not installed; pam_pwquality is not available in PAM stack"
    exit 0
fi

COMMON_PW="/etc/pam.d/common-password"

if [ ! -f "$COMMON_PW" ]; then
    print_result "WARN" "/etc/pam.d/common-password does not exist; cannot verify pam_pwquality usage"
    exit 0
fi

# 3) Check for active pam_pwquality.so line (non-comment password line)
if grep -E '^[[:space:]]*password[[:space:]]+.*pam_pwquality\.so' "$COMMON_PW" | grep -vq '^[[:space:]]*#'; then
    print_result "OK" "pam_pwquality.so is present in /etc/pam.d/common-password"
else
    print_result "WARN" "pam_pwquality.so is not enabled in /etc/pam.d/common-password"
fi
