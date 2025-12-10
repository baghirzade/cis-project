#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_remember"

(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only on systems with libpam-runtime
if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then

    if [ -f /usr/bin/authselect ]; then
        if authselect list-features sssd | grep -q with-pwhistory; then
            if ! authselect check; then
                cat >&2 << 'MSG'
authselect integrity check failed. Remediation aborted!
An authselect profile is not selected or the selected profile is not intact.
It is not recommended to manually edit PAM files when authselect is available.
If the default authselect profile does not cover a specific demand,
a custom authselect profile is recommended.
MSG
                exit 1
            fi

            authselect enable-feature with-pwhistory
            authselect apply-changes -b
        else
            if ! authselect check; then
                cat >&2 << 'MSG'
authselect integrity check failed. Remediation aborted!
An authselect profile is not selected or the selected profile is not intact.
It is not recommended to manually edit PAM files when authselect is available.
If the default authselect profile does not cover a specific demand,
a custom authselect profile is recommended.
MSG
                exit 1
            fi

            CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')

            # If not already using a custom profile, create one preserving enabled features
            if [[ ! $CURRENT_PROFILE == custom/* ]]; then
                ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
                # Replace "local" profile with "sssd" for better security
                if [[ $CURRENT_PROFILE == local ]]; then
                    CURRENT_PROFILE="sssd"
                fi

                authselect create-profile hardening -b "$CURRENT_PROFILE"
                CURRENT_PROFILE="custom/hardening"

                authselect apply-changes -b --backup=before-hardening-custom-profile
                authselect select "$CURRENT_PROFILE"
                for feature in $ENABLED_FEATURES; do
                    authselect enable-feature "$feature"
                done
                authselect apply-changes -b --backup=after-hardening-custom-profile
            fi

            PAM_FILE_NAME=$(basename "cac_pwhistory")
            PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"

            authselect apply-changes -b

            if ! grep -qP "^\s*password\s+requisite\s+pam_pwhistory.so\s*.*" "$PAM_FILE_PATH"; then
                # Line with group+control+module not found – try group+module only.
                if [ "$(grep -cP '^\s*password\s+.*\s+pam_pwhistory.so\s*' "$PAM_FILE_PATH")" -eq 1 ]; then
                    sed -i -E --follow-symlinks "s/^(\s*password\s+).*(\bpam_pwhistory.so.*)/\1requisite \2/" "$PAM_FILE_PATH"
                else
                    echo "password    requisite    pam_pwhistory.so" >> "$PAM_FILE_PATH"
                fi
            fi
        fi
    else
        # authselect is not present – use pam-configs
        conf_name=cac_pwhistory
        conf_path="/usr/share/pam-configs"

        if [ ! -f "$conf_path/$conf_name" ]; then
            cat << 'CFG' > "$conf_path/$conf_name"
Name: pwhistory password history checking
Default: yes
Priority: 1024
Password-Type: Primary
Password: requisite pam_pwhistory.so remember=24 enforce_for_root try_first_pass use_authtok
Password-Initial: requisite pam_pwhistory.so remember=24 enforce_for_root try_first_pass
CFG
        fi

        DEBIAN_FRONTEND=noninteractive pam-auth-update
    fi

    # Enforce remember=<var_password_pam_remember> in cac_pwhistory
    var_password_pam_remember='24'

    sed -i -E '/^Password:/,/^[^[:space:]]/ {
        /pam_pwhistory\.so/ {
            s/\s*remember=[^[:space:]]*//g
            s/$/ remember='"$var_password_pam_remember"'/g
        }
    }' /usr/share/pam-configs/cac_pwhistory

    sed -i -E '/^Password-Initial:/,/^[^[:space:]]/ {
        /pam_pwhistory\.so/ {
            s/\s*remember=[^[:space:]]*//g
            s/$/ remember='"$var_password_pam_remember"'/g
        }
    }' /usr/share/pam-configs/cac_pwhistory

    DEBIAN_FRONTEND=noninteractive pam-auth-update --enable cac_pwhistory

else
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
fi
