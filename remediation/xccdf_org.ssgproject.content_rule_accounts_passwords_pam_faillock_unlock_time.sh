#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_passwords_pam_faillock_unlock_time"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
    exit 0
fi

var_accounts_passwords_pam_faillock_unlock_time='900'

if [ -f /usr/bin/authselect ]; then
    if ! authselect check; then
        cat >&2 << 'MSG'
authselect integrity check failed. Remediation aborted!
This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
It is not recommended to manually edit the PAM files when authselect tool is available.
In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended.
MSG
        exit 1
    fi
    authselect enable-feature with-faillock
    authselect apply-changes -b
else
    conf_name=cac_faillock

    if [ ! -f /usr/share/pam-configs/"$conf_name" ]; then
        cat << 'EOF_PAM' > /usr/share/pam-configs/"$conf_name"
Name: Enable pam_faillock to deny access
Default: yes
Conflicts: faillock
Priority: 0
Auth-Type: Primary
Auth:
    [default=die]                   pam_faillock.so authfail
    sufficient                      pam_faillock.so authsucc
EOF_PAM
    fi

    if [ ! -f /usr/share/pam-configs/"$conf_name"_notify ]; then
        cat << 'EOF_PAM_NOTIFY' > /usr/share/pam-configs/"$conf_name"_notify
Name: Notify of failed login attempts and reset count upon success
Default: yes
Conflicts: faillock_notify
Priority: 1025
Auth-Type: Primary
Auth:
    requisite                       pam_faillock.so preauth
Account-Type: Primary
Account:
    required                        pam_faillock.so
EOF_PAM_NOTIFY
    fi

    DEBIAN_FRONTEND=noninteractive pam-auth-update
fi

AUTH_FILES=("/etc/pam.d/common-auth")
SKIP_FAILLOCK_CHECK=true

FAILLOCK_CONF="/etc/security/faillock.conf"
if [ -f "$FAILLOCK_CONF" ] || [ "$SKIP_FAILLOCK_CHECK" = "true" ]; then
    regex="^\s*unlock_time\s*="
    line="unlock_time = $var_accounts_passwords_pam_faillock_unlock_time"
    if ! grep -qE "$regex" "$FAILLOCK_CONF" 2>/dev/null; then
        echo "$line" >> "$FAILLOCK_CONF"
    else
        sed -i --follow-symlinks 's|^\s*\(unlock_time\s*=\s*\)\(\S\+\)|\1'"$var_accounts_passwords_pam_faillock_unlock_time"'|g' "$FAILLOCK_CONF"
    fi
else
    for pam_file in "${AUTH_FILES[@]}"; do
        if ! grep -qE '^\s*auth.*pam_faillock\.so\s+(preauth|authfail).*unlock_time' "$pam_file"; then
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*preauth.*/ s/$/ unlock_time='"$var_accounts_passwords_pam_faillock_unlock_time"'/' "$pam_file"
            sed -i --follow-symlinks '/^auth.*required.*pam_faillock\.so.*authfail.*/ s/$/ unlock_time='"$var_accounts_passwords_pam_faillock_unlock_time"'/' "$pam_file"
        else
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*preauth.*\)\('"unlock_time"'=\)\S\+\b\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_unlock_time"'\3/' "$pam_file"
            sed -i --follow-symlinks 's/\(^auth.*required.*pam_faillock\.so.*authfail.*\)\('"unlock_time"'=\)\S\+\b\(.*\)/\1\2'"$var_accounts_passwords_pam_faillock_unlock_time"'\3/' "$pam_file"
        fi
    done
fi
