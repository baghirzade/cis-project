#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_warn_age_login_defs"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then

    var_accounts_password_warn_age_login_defs='7'

    # Strip any search characters in the key arg so that the key can be replaced without
    # adding any search characters to the config file.
    stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^PASS_WARN_AGE")

    # shellcheck disable=SC2059
    printf -v formatted_output "%s %s" "$stripped_key" "$var_accounts_password_warn_age_login_defs"

    LOGIN_DEFS="/etc/login.defs"

    if [ ! -e "$LOGIN_DEFS" ]; then
        (>&2 echo "Warning: ${LOGIN_DEFS} does not exist, creating it")
        touch "$LOGIN_DEFS"
    fi

    if [ ! -w "$LOGIN_DEFS" ]; then
        (>&2 echo "Cannot remediate: ${LOGIN_DEFS} is not writable")
        exit 1
    fi

    # If the key exists, change it. Otherwise, add it to the config_file.
    if LC_ALL=C grep -q -m 1 -i -e "^PASS_WARN_AGE\\>" "$LOGIN_DEFS"; then
        escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
        LC_ALL=C sed -i --follow-symlinks "s/^PASS_WARN_AGE\\>.*/$escaped_formatted_output/gi" "$LOGIN_DEFS"
    else
        if [[ -s "$LOGIN_DEFS" ]] && [[ -n "$(tail -c 1 -- "$LOGIN_DEFS" || true)" ]]; then
            LC_ALL=C sed -i --follow-symlinks '$a'\\ "$LOGIN_DEFS"
        fi
        printf '%s\n' "$formatted_output" >> "$LOGIN_DEFS"
    fi

else
    >&2 echo "Remediation is not applicable: 'login' package is not installed"
    exit 0
fi

exit 0
