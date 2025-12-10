#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_maximum_age_login_defs"

(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only if 'login' package is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    (>&2 echo "Remediation is not applicable: package 'login' is not installed")
    exit 0
fi

LOGIN_DEFS="/etc/login.defs"
TARGET_DAYS="365"

if [ ! -w "$LOGIN_DEFS" ]; then
    (>&2 echo "Cannot remediate: ${LOGIN_DEFS} is not writable")
    exit 1
fi

stripped_key="PASS_MAX_DAYS"
formatted_output="${stripped_key} ${TARGET_DAYS}"

# If the key exists, change it. Otherwise, append it to the file.
if LC_ALL=C grep -q -m 1 -i -e "^PASS_MAX_DAYS\\>" "$LOGIN_DEFS"; then
    escaped_formatted_output="$(printf '%s\n' "$formatted_output" | sed -e 's|/|\\/|g')"
    LC_ALL=C sed -i --follow-symlinks "s/^PASS_MAX_DAYS\\>.*/${escaped_formatted_output}/gi" "$LOGIN_DEFS"
else
    # Ensure file ends with a newline before appending
    if [ -s "$LOGIN_DEFS" ] && [ -n "$(tail -c 1 -- "$LOGIN_DEFS" || true)" ]; then
        LC_ALL=C sed -i --follow-symlinks '$a\' "$LOGIN_DEFS"
    fi
    printf '%s\n' "$formatted_output" >> "$LOGIN_DEFS"
fi

exit 0
