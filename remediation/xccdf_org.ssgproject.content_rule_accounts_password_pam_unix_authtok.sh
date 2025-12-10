#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_authtok"

(>&2 echo "Remediating: ${RULE_ID}")

# Applicable only if libpam-runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
    exit 0
fi

config_file="/usr/share/pam-configs/cac_unix"
conf_name="cac_unix"
conf_path="/usr/share/pam-configs"

# If cac_unix does not exist, clone unix profile (if original, unmodified)
if [ ! -f "$conf_path/$conf_name" ]; then
    if [ -f "$conf_path/unix" ]; then
        if grep -q "$(md5sum "$conf_path/unix" | cut -d ' ' -f 1)" /var/lib/dpkg/info/libpam-runtime.md5sums; then
            cp "$conf_path/unix" "$conf_path/$conf_name"
            sed -i 's/Priority: [0-9]\+/Priority: 257\
Conflicts: unix/' "$conf_path/$conf_name"
            DEBIAN_FRONTEND=noninteractive pam-auth-update
        else
            echo "Not applicable - checksum of $conf_path/unix does not match the original." >&2
        fi
    else
        echo "Not applicable - $conf_path/unix does not exist" >&2
    fi
fi

# Ensure pam_unix.so line has use_authtok option
if [ -f "$config_file" ]; then
    sed -i -E '/^Password:/,/^[^[:space:]]/ {
        /pam_unix\.so/ {
            /use_authtok/! s/$/ use_authtok/g
        }
    }' "$config_file"
fi

# Switch from unix to cac_unix in PAM configuration
DEBIAN_FRONTEND=noninteractive pam-auth-update --remove unix --enable cac_unix
