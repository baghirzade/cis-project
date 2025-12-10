#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_authtok"
CONF_FILE="/usr/share/pam-configs/cac_unix"

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

# 2) cac_unix konfiq faylı mövcud olmalıdır
if [ ! -f "$CONF_FILE" ]; then
    print_result "WARN" "PAM configuration $CONF_FILE does not exist (unix profile likely in use)"
    exit 0
fi

# 3) faylda pam_unix.so olmalıdır
if ! grep -qE 'pam_unix\.so' "$CONF_FILE"; then
    print_result "WARN" "pam_unix is not referenced in $CONF_FILE"
    exit 0
fi

# 4) pam_unix.so sətrində use_authtok olmalıdır
if ! grep -qE 'pam_unix\.so[[:space:]].*\buse_authtok\b' "$CONF_FILE"; then
    print_result "WARN" "pam_unix in $CONF_FILE does not have use_authtok option set"
    exit 0
fi

# 5) cac_unix PAM-da enabled olmalıdır
if pam-auth-update --list 2>/dev/null | grep -q 'cac_unix.*\[enabled\]'; then
    print_result "OK" "cac_unix is enabled and pam_unix uses use_authtok"
else
    print_result "WARN" "pam_unix uses use_authtok but cac_unix is not enabled in PAM"
fi
