#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_no_remember"

# Remediation is applicable only if libpam-runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation is not applicable: package 'libpam-runtime' is not installed"
    exit 0
fi

conf_name="cac_unix"
conf_path="/usr/share/pam-configs"

# If cac_unix does not exist, clone from unix (if original untouched)
if [ ! -f "$conf_path/$conf_name" ]; then
    if [ -f "$conf_path/unix" ]; then
        if grep -q "$(md5sum "$conf_path/unix" | cut -d ' ' -f 1)" /var/lib/dpkg/info/libpam-runtime.md5sums; then
            cp "$conf_path/unix" "$conf_path/$conf_name"
            sed -i 's/Priority: [0-9]\+/Priority: 257\
Conflicts: unix/' "$conf_path/$conf_name"
            DEBIAN_FRONTEND=noninteractive pam-auth-update
        else
            >&2 echo "Not applicable - checksum of $conf_path/unix does not match the original."
            exit 0
        fi
    else
        >&2 echo "Not applicable - $conf_path/unix does not exist."
        exit 0
    fi
fi

config_file="/usr/share/pam-configs/cac_unix"

# Remove any 'remember=...' option from pam_unix.so lines in Password / Password-Initial blocks
sed -i -E '/^Password(-Initial)?:/,/^[^[:space:]]/ {
    /pam_unix\.so/ {
        s/\s*\bremember=[^[:space:]]+\b//g
    }
}' "$config_file"

DEBIAN_FRONTEND=noninteractive pam-auth-update

exit 0
