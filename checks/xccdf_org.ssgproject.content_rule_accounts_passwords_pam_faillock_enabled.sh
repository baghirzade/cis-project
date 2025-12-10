#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_passwords_pam_faillock_enabled"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpam-runtime not installed → NOTAPPL
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

# 2) If authselect is present, check if with-faillock feature is enabled
if command -v authselect >/dev/null 2>&1; then
    if ! authselect check >/dev/null 2>&1; then
        print_result "WARN" "authselect profile is not valid (with-faillock cannot be verified)"
        exit 0
    fi

    if authselect current 2>/dev/null | grep -q 'with-faillock'; then
        print_result "OK" "authselect profile has with-faillock feature enabled"
        exit 0
    fi
    print_result "WARN" "authselect profile does not have with-faillock feature enabled"
    exit 0
fi

# 3) No authselect → check PAM stack directly
PAM_FILES=(
    "/etc/pam.d/common-auth"
    "/etc/pam.d/common-account"
)

found="false"
for f in "${PAM_FILES[@]}"; do
    if [ -f "$f" ] && grep -q 'pam_faillock\.so' "$f"; then
        found="true"
        break
    fi
done

if [ "$found" = "true" ]; then
    print_result "OK" "pam_faillock.so is configured in the PAM stack (common-auth/account)"
else
    print_result "WARN" "pam_faillock.so is not enabled in common-auth/common-account PAM stack"
fi
