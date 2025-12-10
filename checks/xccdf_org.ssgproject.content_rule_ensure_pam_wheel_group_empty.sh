#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_pam_wheel_group_empty"

# If libpam-runtime is not installed, consider control not applicable
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|libpam-runtime package is not installed (control not applicable)"
    exit 0
fi

pam_wheel_group="sugroup"

# Check if group exists
if ! getent group "${pam_wheel_group}" >/dev/null 2>&1; then
    echo "WARN|${RULE_ID}|Group '${pam_wheel_group}' does not exist (remediation will create it)"
    exit 0
fi

# Get member list
members="$(getent group "${pam_wheel_group}" | awk -F: '{print $4}')"

if [[ -z "${members}" ]]; then
    echo "OK|${RULE_ID}|Group '${pam_wheel_group}' exists and has no members"
else
    echo "WARN|${RULE_ID}|Group '${pam_wheel_group}' has members: ${members}"
fi

exit 0
