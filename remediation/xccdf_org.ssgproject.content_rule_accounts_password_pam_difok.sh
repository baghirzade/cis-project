#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_difok"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpwquality1 is not installed'
    exit 0
fi

var_password_pam_difok='2'

conf_name=cac_pwquality
conf_path="/usr/share/pam-configs"
pwq_conf="/etc/security/pwquality.conf"

# Ensure pam-config entry for pwquality exists
if [ ! -f "${conf_path}/${conf_name}" ]; then
    cat << 'EOF_PWQ' > "${conf_path}/${conf_name}"
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
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^difok")

# shellcheck disable=SC2059
printf -v formatted_output "%s = %s" "$stripped_key" "$var_password_pam_difok"

# Ensure pwquality.conf exists
if [ ! -f "$pwq_conf" ]; then
    touch "$pwq_conf"
fi

# If the key exists, change it. Otherwise, add it to the config_file.
# We search for the key string followed by a word boundary (matched by \>),
# so if we search for 'setting', 'setting2' won't match.
if LC_ALL=C grep -q -m 1 -i -e "^difok\\>" "$pwq_conf"; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^difok\\>.*/$escaped_formatted_output/gi" "$pwq_conf"
else
    if [[ -s "$pwq_conf" ]] && [[ -n "$(tail -c 1 -- "$pwq_conf" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "$pwq_conf"
    fi
    printf '%s\n' "$formatted_output" >> "$pwq_conf"
fi
