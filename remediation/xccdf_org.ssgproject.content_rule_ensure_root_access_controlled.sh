#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_root_access_controlled"

# Remediation is applicable only if PAM runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation for ${RULE_ID} is not applicable: libpam-runtime package is not installed"
    exit 0
fi

PAM_SU_FILE="/etc/pam.d/su"
PAM_WHEEL_GROUP="sugroup"

if [ ! -f "${PAM_SU_FILE}" ]; then
    >&2 echo "Remediation for ${RULE_ID} skipped: ${PAM_SU_FILE} does not exist (su not configured)"
    exit 0
fi

# Ensure the controlling group exists (same as rule 81)
if ! getent group "${PAM_WHEEL_GROUP}" >/dev/null 2>&1; then
    if ! /usr/sbin/groupadd "${PAM_WHEEL_GROUP}"; then
        >&2 echo "Remediation for ${RULE_ID} failed: could not create group '${PAM_WHEEL_GROUP}'"
        exit 1
    fi
fi

# If pam_wheel line already exists, normalize it
if grep -Eq '^\s*auth\s+required\s+pam_wheel\.so' "${PAM_SU_FILE}"; then
    sed -Ei "s|^\s*auth\s+required\s+pam_wheel\.so.*|auth     required pam_wheel.so use_uid group=${PAM_WHEEL_GROUP}|" "${PAM_SU_FILE}"
else
    # Otherwise, insert a proper line near the top (before other auth lines if possible)
    if grep -qE '^\s*auth\b' "${PAM_SU_FILE}"; then
        # Insert before the first 'auth' line
        sed -i "0,/^\s*auth\b/s//auth     required pam_wheel.so use_uid group=${PAM_WHEEL_GROUP}\n&/" "${PAM_SU_FILE}"
    else
        # Fallback: append at the beginning
        sed -i "1i auth     required pam_wheel.so use_uid group=${PAM_WHEEL_GROUP}" "${PAM_SU_FILE}"
    fi
fi

exit 0
