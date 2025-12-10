#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_passwords_pam_faillock_unlock_time"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

REQUIRED_MIN=900

# 1) libpam-runtime yoxdursa → NOTAPPL
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

FAILLOCK_CONF="/etc/security/faillock.conf"

# 2) faillock.conf varsa → unlock_time oxu
if [ -f "$FAILLOCK_CONF" ]; then
    raw_value="$(grep -E '^[[:space:]]*unlock_time[[:space:]]*=' "$FAILLOCK_CONF" | tail -n 1 || true)"

    if [ -z "$raw_value" ]; then
        print_result "WARN" "unlock_time is not set in /etc/security/faillock.conf"
        exit 0
    fi

    # unlock_time = 900, 900s və s. kimi hallardan rəqəmi çıxarırıq
    value="$(echo "$raw_value" | sed -E 's/^[[:space:]]*unlock_time[[:space:]]*=[[:space:]]*//; s/[^0-9].*$//')"

    if ! [[ "$value" =~ ^[0-9]+$ ]]; then
        print_result "WARN" "unlock_time in /etc/security/faillock.conf is not a numeric value"
        exit 0
    fi

    # 0 → “until manually unlocked” – tələbdən daha sərtdir, OK hesab edirik
    if [ "$value" -eq 0 ] || [ "$value" -ge "$REQUIRED_MIN" ]; then
        print_result "OK" "unlock_time is set to ${value} in /etc/security/faillock.conf (meets requirement)"
    else
        print_result "WARN" "unlock_time is set to ${value} (required >= ${REQUIRED_MIN} seconds or 0)"
    fi

    exit 0
fi

# 3) faillock.conf yoxdur → pam_faillock ümumiyyətlə konfiqurasiya olunubmu?
PAM_FILES=(
    "/etc/pam.d/common-auth"
    "/etc/pam.d/common-account"
)

found_faillock="false"
for f in "${PAM_FILES[@]}"; do
    if [ -f "$f" ] && grep -q 'pam_faillock\.so' "$f"; then
        found_faillock="true"
        break
    fi
done

if [ "$found_faillock" = "false" ]; then
    print_result "WARN" "pam_faillock is not configured and /etc/security/faillock.conf does not exist (unlock_time not enforced)"
else
    print_result "WARN" "pam_faillock is configured but /etc/security/faillock.conf does not exist; unlock_time is using default"
fi
