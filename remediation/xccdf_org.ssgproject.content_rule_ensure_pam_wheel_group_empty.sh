#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_pam_wheel_group_empty"

# Remediation is applicable only if libpam-runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation for ${RULE_ID} is not applicable: libpam-runtime package is not installed"
    exit 0
fi

pam_wheel_group="sugroup"

# Ensure group exists (use full path to groupadd as in original fix)
if ! getent group "${pam_wheel_group}" >/dev/null 2>&1; then
    if ! /usr/sbin/groupadd "${pam_wheel_group}"; then
        >&2 echo "Remediation for ${RULE_ID} failed: could not create group '${pam_wheel_group}'"
        exit 1
    fi
fi

# Ensure group has no members
if ! gpasswd -M '' "${pam_wheel_group}" >/dev/null 2>&1; then
    >&2 echo "Remediation for ${RULE_ID} failed: could not clear members of '${pam_wheel_group}'"
    exit 1
fi

exit 0
