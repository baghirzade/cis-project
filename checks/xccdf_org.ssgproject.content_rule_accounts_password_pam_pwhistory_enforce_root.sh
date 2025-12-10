#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_enforce_root"
TITLE="pam_pwhistory must enforce history for root (enforce_for_root)"

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

    # Check for active pam_pwhistory line with enforce_for_root
    if grep -Eq '^[[:space:]]*password[[:space:]].*pam_pwhistory\.so.*enforce_for_root' "$pam_file"; then
        echo "OK|$RULE_ID|pam_pwhistory is configured with enforce_for_root in $pam_file"
    else
        echo "WARN|$RULE_ID|pam_pwhistory is not configured with enforce_for_root in $pam_file"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
