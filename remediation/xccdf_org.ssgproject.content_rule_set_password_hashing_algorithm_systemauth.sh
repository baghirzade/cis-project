#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_password_hashing_algorithm_systemauth"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
    exit 0
fi

var_password_hashing_algorithm_pam='yescrypt'

conf_name="cac_unix"
conf_path="/usr/share/pam-configs"

# Ensure cac_unix pam-config exists (clone from unix if original, untouched)
if [ ! -f "$conf_path/$conf_name" ]; then
    if [ -f "$conf_path/unix" ]; then
        if grep -q "$(md5sum "$conf_path/unix" | cut -d ' ' -f 1)" /var/lib/dpkg/info/libpam-runtime.md5sums; then
            cp "$conf_path/unix" "$conf_path/$conf_name"
            sed -i 's/Priority: [0-9]\+/Priority: 257\
Conflicts: unix/' "$conf_path/$conf_name"
            DEBIAN_FRONTEND=noninteractive pam-auth-update
        else
            >&2 echo "Not applicable - checksum of $conf_path/unix does not match the original."
        fi
    else
        >&2 echo "Not applicable - $conf_path/unix does not exist."
    fi
fi

PAM_FILE_PATH="/usr/share/pam-configs/cac_unix"

# Ensure all hashing algorithm options are removed before setting yescrypt
declare -a HASHING_ALGORITHMS_OPTIONS=("sha512" "yescrypt" "gost_yescrypt" "blowfish" "sha256" "md5" "bigcrypt")

for hash_option in "${HASHING_ALGORITHMS_OPTIONS[@]}"; do
    sed -i -E '/^Password:/,/^[^[:space:]]/ {
        /pam_unix\.so/ {
            s/\s*\b'"$hash_option"'\b//g
        }
    }' "$PAM_FILE_PATH"

    sed -i -E '/^Password-Initial:/,/^[^[:space:]]/ {
        /pam_unix\.so/ {
            s/\s*\b'"$hash_option"'\b//g
        }
    }' "$PAM_FILE_PATH"
done

# Add yescrypt to Password section if missing
if ! grep -qE '^Password:[[:space:]]*$' -A1 "$PAM_FILE_PATH" | grep -qE 'pam_unix\.so.*\byescrypt\b'; then
    sed -i -E '/^Password:/,/^[^[:space:]]/ {
        /pam_unix\.so/ {
            s/$/ '"$var_password_hashing_algorithm_pam"'/g
        }
    }' "$PAM_FILE_PATH"
fi

# Add yescrypt to Password-Initial section if missing
if ! grep -qE '^Password-Initial:[[:space:]]*$' -A1 "$PAM_FILE_PATH" | grep -qE 'pam_unix\.so.*\byescrypt\b'; then
    sed -i -E '/^Password-Initial:/,/^[^[:space:]]/ {
        /pam_unix\.so/ {
            s/$/ '"$var_password_hashing_algorithm_pam"'/g
        }
    }' "$PAM_FILE_PATH"
fi

DEBIAN_FRONTEND=noninteractive pam-auth-update
