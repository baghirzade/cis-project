#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_root_access_controlled"

# Control is only applicable if PAM runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|libpam-runtime package is not installed (control not applicable)"
    exit 0
fi

PAM_SU_FILE="/etc/pam.d/su"
PAM_WHEEL_GROUP="sugroup"

if [ ! -f "${PAM_SU_FILE}" ]; then
    echo "NOTAPPL|${RULE_ID}|${PAM_SU_FILE} does not exist (su is not configured with PAM)"
    exit 0
fi

# Check that su is restricted via pam_wheel.so, using use_uid and group=sugroup
if grep -Eq '^\s*auth\s+required\s+pam_wheel\.so\b.*\buse_uid\b.*\bgroup=sugroup\b' "${PAM_SU_FILE}"; then
    echo "OK|${RULE_ID}|Root access via 'su' is restricted to group '${PAM_WHEEL_GROUP}' using pam_wheel.so (use_uid)"
else
    echo "WARN|${RULE_ID}|Root access via 'su' is not properly restricted with pam_wheel.so use_uid group='${PAM_WHEEL_GROUP}'"
fi

exit 0
