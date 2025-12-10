#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_use_authtok"
CONF_FILE="/usr/share/pam-configs/cac_pwhistory"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1) libpam-runtime yoxdursa → NOTAPPL
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

# 2) authselect varsa – eyni stildə WARN (bu checker authselect profilini analiz etmir)
if command -v authselect >/dev/null 2>&1; then
    print_result "WARN" "System uses authselect; pam_pwhistory use_authtok option is not validated by this checker"
    exit 0
fi

# 3) pam-config faylı mövcud olmalıdır
if [ ! -f "$CONF_FILE" ]; then
    print_result "WARN" "pam_pwhistory configuration file $CONF_FILE is missing"
    exit 0
fi

# 4) ən azı bir pam_pwhistory.so sətri və onda use_authtok olmalıdır
if ! grep -qE 'pam_pwhistory\.so' "$CONF_FILE"; then
    print_result "WARN" "pam_pwhistory is not referenced in $CONF_FILE"
    exit 0
fi

if ! grep -qE 'pam_pwhistory\.so[[:space:]].*\buse_authtok\b' "$CONF_FILE"; then
    print_result "WARN" "pam_pwhistory in $CONF_FILE does not have use_authtok option set"
    exit 0
fi

# 5) cac_pwhistory modulunun PAM-da enabled olduğunu yoxla
if pam-auth-update --list 2>/dev/null | grep -q 'cac_pwhistory.*\[enabled\]'; then
    print_result "OK" "pam_pwhistory is configured with use_authtok and cac_pwhistory is enabled"
else
    print_result "WARN" "pam_pwhistory has use_authtok but cac_pwhistory is not enabled in PAM"
fi
