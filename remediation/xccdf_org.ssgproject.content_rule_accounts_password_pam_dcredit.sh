#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_dcredit"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpwquality1 is not installed'
    exit 0
fi

var_password_pam_dcredit='-1'

conf_name=cac_pwquality
if [ ! -f /usr/share/pam-configs/"$conf_name" ]; then
    cat << 'EOF_PWQ' > /usr/share/pam-configs/"$conf_name"
Name: Pwquality password strength checking
Default: yes
Priority: 1025
Conflicts: cracklib, pwquality
Password-Type: Primary
Password:
    requisite                   pam_pwquality.so
EOF_PWQ
fi

DEBIAN_FRONTEND=noninteractive pam-auth-update

# Strip any search characters in the key arg so that the key can be replaced without
# adding any search characters to the config file.
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^dcredit")

# shellcheck disable=SC2059
printf -v formatted_output "%s = %s" "$stripped_key" "$var_password_pam_dcredit"

PWQ_CONF="/etc/security/pwquality.conf"

# If the key exists, change it. Otherwise, add it to the config_file.
# We search for the key string followed by a word boundary (matched by \>),
# so if we search for 'setting', 'setting2' won't match.
if LC_ALL=C grep -q -m 1 -i -e "^dcredit\\>" "$PWQ_CONF"; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^dcredit\\>.*/$escaped_formatted_output/gi" "$PWQ_CONF"
else
    if [[ -s "$PWQ_CONF" ]] && [[ -n "$(tail -c 1 -- "$PWQ_CONF" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "$PWQ_CONF"
    fi
    printf '%s\n' "$formatted_output" >> "$PWQ_CONF"
fi
