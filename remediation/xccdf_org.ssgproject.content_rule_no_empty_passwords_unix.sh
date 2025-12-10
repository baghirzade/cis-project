#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_empty_passwords_unix"

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$' \
   || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation is not applicable for ${RULE_ID} (libpam-runtime or linux-base not installed)"
    exit 0
fi

conf_name="cac_unix"
conf_path="/usr/share/pam-configs"
config_file="${conf_path}/${conf_name}"

# Ensure cac_unix profile exists (clone from unix if it is still original)
if [[ ! -f "$config_file" ]]; then
    if [[ -f "${conf_path}/unix" ]]; then
        if grep -q "$(md5sum "${conf_path}/unix" | cut -d ' ' -f 1)" /var/lib/dpkg/info/libpam-runtime.md5sums 2>/dev/null; then
            cp "${conf_path}/unix" "$config_file"
            sed -i 's/Priority: [0-9]\+/Priority: 257\
Conflicts: unix/' "$config_file"
            DEBIAN_FRONTEND=noninteractive pam-auth-update >/dev/null 2>&1 || true
        else
            >&2 echo "Remediation for ${RULE_ID}: ${conf_path}/unix has been modified; not cloning to ${config_file}"
        fi
    else
        >&2 echo "Remediation for ${RULE_ID}: ${conf_path}/unix does not exist; cannot create ${config_file}"
        exit 0
    fi
fi

if [[ ! -f "$config_file" ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: ${config_file} does not exist"
    exit 1
fi

# Remove 'nullok' from pam_unix.so lines
sed -i '/pam_unix\.so/s/\<nullok\>//g' "$config_file"

# Apply PAM configuration changes
DEBIAN_FRONTEND=noninteractive pam-auth-update >/dev/null 2>&1 || true

exit 0
