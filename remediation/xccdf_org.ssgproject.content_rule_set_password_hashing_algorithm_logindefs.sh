#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_set_password_hashing_algorithm_logindefs"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, login package is not installed'
    exit 0
fi

var_password_hashing_algorithm='SHA512|YESCRYPT'

# Allow multiple algorithms, but choose the first one for remediation
var_password_hashing_algorithm="$(echo "$var_password_hashing_algorithm" | cut -d '|' -f 1)"

# Strip any search characters in the key arg so that the key can be replaced without
# adding any search characters to the config file.
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^ENCRYPT_METHOD")

# shellcheck disable=SC2059
printf -v formatted_output "%s %s" "$stripped_key" "$var_password_hashing_algorithm"

LOGIN_DEFS="/etc/login.defs"

# If the key exists, change it. Otherwise, add it to the config file.
# We search for the key string followed by a word boundary (matched by \>),
# so if we search for 'setting', 'setting2' won't match.
if LC_ALL=C grep -q -m 1 -i -e "^ENCRYPT_METHOD\\>" "$LOGIN_DEFS" 2>/dev/null; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^ENCRYPT_METHOD\\>.*/$escaped_formatted_output/gi" "$LOGIN_DEFS"
else
    # Make sure file ends with newline before appending
    if [[ -s "$LOGIN_DEFS" ]] && [[ -n "$(tail -c 1 -- "$LOGIN_DEFS" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "$LOGIN_DEFS"
    fi
    printf '%s\n' "$formatted_output" >> "$LOGIN_DEFS"
fi
