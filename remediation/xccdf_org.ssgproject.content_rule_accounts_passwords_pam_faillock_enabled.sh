#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_passwords_pam_faillock_enabled"

(>&2 echo "Remediating: ${RULE_ID}")

# Applicable only if libpam-runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
    exit 0
fi

# If authselect exists, enable with-faillock feature
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
    conf_name="cac_faillock"
    base_dir="/usr/share/pam-configs"

    if [ ! -f "${base_dir}/${conf_name}" ]; then
        cat << 'EOF_PAM' > "${base_dir}/${conf_name}"
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

    if [ ! -f "${base_dir}/${conf_name}_notify" ]; then
        cat << 'EOF_PAM_NOTIFY' > "${base_dir}/${conf_name}_notify"
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
