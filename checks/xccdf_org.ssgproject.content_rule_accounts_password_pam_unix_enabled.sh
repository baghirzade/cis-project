#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_enabled"
TITLE="Local UNIX passwords via pam_unix must be enabled"

run() {
    # Applicability: only if libpam-runtime is installed
    if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
        echo "NOTAPPL|$RULE_ID|libpam-runtime is not installed (control not applicable)"
        return 0
    fi

    local pam_file="/etc/pam.d/common-password"

    if [ ! -f "$pam_file" ]; then
        echo "WARN|$RULE_ID|PAM file $pam_file does not exist"
        return 0
    fi

    # Look for an active (non-commented) pam_unix.so password line
    if grep -Eq '^[[:space:]]*password[[:space:]].*pam_unix\.so' "$pam_file"; then
        echo "OK|$RULE_ID|pam_unix is enabled in $pam_file for password authentication"
    else
        echo "WARN|$RULE_ID|pam_unix is not enabled in $pam_file for password authentication"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
