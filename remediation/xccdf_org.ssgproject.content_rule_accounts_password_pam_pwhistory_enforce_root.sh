#!/usr/bin/env bash
set -euo pipefail

###############################################################################
# BEGIN fix (39 / 405) for 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_enforce_root'
###############################################################################
(>&2 echo "Remediating rule 39/405: 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_enforce_root'")
# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then

if [ -f /usr/bin/authselect ]; then
    if authselect list-features sssd | grep -q with-pwhistory; then
        if ! authselect check; then
        echo "
        authselect integrity check failed. Remediation aborted!
        This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
        It is not recommended to manually edit the PAM files when authselect tool is available.
        In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
        exit 1
        fi
        authselect enable-feature with-pwhistory

        authselect apply-changes -b
    else
        
        if ! authselect check; then
        echo "
        authselect integrity check failed. Remediation aborted!
        This remediation could not be applied because an authselect profile was not selected or the selected profile is not intact.
        It is not recommended to manually edit the PAM files when authselect tool is available.
        In cases where the default authselect profile does not cover a specific demand, a custom authselect profile is recommended."
        exit 1
        fi

        CURRENT_PROFILE=$(authselect current -r | awk '{ print $1 }')
        # If not already in use, a custom profile is created preserving the enabled features.
        if [[ ! $CURRENT_PROFILE == custom/* ]]; then
            ENABLED_FEATURES=$(authselect current | tail -n+3 | awk '{ print $2 }')
            # The "local" profile does not contain essential security features required by multiple Benchmarks.
            # If currently used, it is replaced by "sssd", which is the best option in this case.
            if [[ $CURRENT_PROFILE == local ]]; then
                CURRENT_PROFILE="sssd"
            fi
            authselect create-profile hardening -b $CURRENT_PROFILE
            CURRENT_PROFILE="custom/hardening"
            
            authselect apply-changes -b --backup=before-hardening-custom-profile
            authselect select $CURRENT_PROFILE
            for feature in $ENABLED_FEATURES; do
                authselect enable-feature $feature;
            done
            
            authselect apply-changes -b --backup=after-hardening-custom-profile
        fi
        PAM_FILE_NAME=$(basename "cac_pwhistory")
        PAM_FILE_PATH="/etc/authselect/$CURRENT_PROFILE/$PAM_FILE_NAME"

        authselect apply-changes -b
        
        if ! grep -qP "^\s*password\s+requisite\s+pam_pwhistory.so\s*.*" "$PAM_FILE_PATH"; then
            # Line matching group + control + module was not found. Check group + module.
            if [ "$(grep -cP '^\s*password\s+.*\s+pam_pwhistory.so\s*' "$PAM_FILE_PATH")" -eq 1 ]; then
                # The control is updated only if one single line matches.
                sed -i -E --follow-symlinks "s/^(\s*password\s+).*(\bpam_pwhistory.so.*)/\1requisite \2/" "$PAM_FILE_PATH"
            else
                echo "password    requisite    pam_pwhistory.so" >> "$PAM_FILE_PATH"
            fi
        fi
    fi
else

conf_name=cac_pwhistory
conf_path="/usr/share/pam-configs"

if [ ! -f "$conf_path"/"$conf_name" ]; then
    cat << EOF_INNER > "$conf_path"/"$conf_name"
Name: pwhistory password history checking
Default: yes
Priority: 1024
Password-Type: Primary
Password: requisite pam_pwhistory.so remember=24 enforce_for_root try_first_pass use_authtok
Password-Initial: requisite pam_pwhistory.so remember=24 enforce_for_root try_first_pass
EOF_INNER
fi

DEBIAN_FRONTEND=noninteractive pam-auth-update

fi
conf_file=/usr/share/pam-configs/cac_pwhistory
if ! grep -qE 'pam_pwhistory\.so\s+[^#\n]*\benforce_for_root\b' "$conf_file"; then
	sed -i -E '/^Password:/,/^[^[:space:]]/ {
    /pam_pwhistory\.so/ {
        s/$/ enforce_for_root/g
    }
    }' "$conf_file"

    sed -i -E '/^Password-Initial:/,/^[^[:space:]]/ {
    /pam_pwhistory\.so/ {
        s/$/ enforce_for_root/g
    }
    }' "$conf_file"
fi

DEBIAN_FRONTEND=noninteractive pam-auth-update --enable cac_pwhistory

else
    >&2 echo 'Remediation is not applicable, nothing was done'
fi

# END fix for 'xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_enforce_root'
###############################################################################
