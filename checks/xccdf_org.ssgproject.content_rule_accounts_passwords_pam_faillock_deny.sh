#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_passwords_pam_faillock_deny"
FAILLOCK_CONF="/etc/security/faillock.conf"
REQUIRED_DENY="4"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpam-runtime yoxdursa -> NOTAPPL
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

# 2) PAM stack-də ümumiyyətlə pam_faillock.so istifadə olunmur → WARN
if ! grep -Rqs 'pam_faillock\.so' /etc/pam.d 2>/dev/null; then
    print_result "WARN" "pam_faillock is not configured in the PAM stack"
    exit 0
fi

# 3) faillock.conf faylı yoxdursa → WARN
if [ ! -f "$FAILLOCK_CONF" ]; then
    print_result "WARN" "$FAILLOCK_CONF does not exist (deny value not configured)"
    exit 0
fi

# 4) deny parametrini oxu
current_deny="$(awk -F '=' '
    /^[[:space:]]*deny[[:space:]]*=/ {
        gsub(/[[:space:]]*/, "", $2);
        print $2;
        exit
    }' "$FAILLOCK_CONF" || true)"

if [ -z "$current_deny" ]; then
    print_result "WARN" "deny is not configured in $FAILLOCK_CONF"
    exit 0
fi

if [ "$current_deny" != "$REQUIRED_DENY" ]; then
    print_result "WARN" "deny is set to $current_deny in $FAILLOCK_CONF (expected $REQUIRED_DENY)"
    exit 0
fi

# Hər şey qaydasındadır
print_result "OK" "pam_faillock deny is correctly set to $REQUIRED_DENY in $FAILLOCK_CONF"
