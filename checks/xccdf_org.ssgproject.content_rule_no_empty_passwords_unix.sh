#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_empty_passwords_unix"

# Applicability check: require libpam-runtime and linux-base
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$' \
   || ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|libpam-runtime or linux-base is not installed (control not applicable)"
    exit 0
fi

CONF_PATH="/usr/share/pam-configs"
CAC_UNIX="${CONF_PATH}/cac_unix"
UNIX_CFG="${CONF_PATH}/unix"

CONFIG_FILE=""

if [[ -r "$CAC_UNIX" ]]; then
    CONFIG_FILE="$CAC_UNIX"
elif [[ -r "$UNIX_CFG" ]]; then
    CONFIG_FILE="$UNIX_CFG"
else
    echo "FAIL|${RULE_ID}|Neither ${CAC_UNIX} nor ${UNIX_CFG} is readable; cannot inspect pam_unix configuration"
    exit 0
fi

# Look for pam_unix.so with 'nullok'
if grep -Eq 'pam_unix\.so' "$CONFIG_FILE"; then
    if grep -Eq 'pam_unix\.so.*\bnullok\b' "$CONFIG_FILE"; then
        echo "WARN|${RULE_ID}|pam_unix is configured with 'nullok' in ${CONFIG_FILE} (allows null passwords)"
    else
        echo "OK|${RULE_ID}|pam_unix is not configured with 'nullok' in ${CONFIG_FILE}"
    fi
else
    echo "WARN|${RULE_ID}|No pam_unix.so entries found in ${CONFIG_FILE}; cannot confirm null password behavior"
fi

exit 0
