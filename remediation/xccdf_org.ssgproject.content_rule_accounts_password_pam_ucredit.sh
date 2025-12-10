#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_ucredit"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpwquality1 is not installed'
    exit 0
fi

var_password_pam_ucredit='-1'

conf_name="cac_pwquality"
conf_path="/usr/share/pam-configs"

# Ensure pam-config snippet exists
if [ ! -f "${conf_path}/${conf_name}" ]; then
    cat << 'EOF_INNER' > "${conf_path}/${conf_name}"
Name: Pwquality password strength checking
Default: yes
Priority: 1025
Conflicts: cracklib, pwquality
Password-Type: Primary
Password:
    requisite                   pam_pwquality.so
EOF_INNER
fi

DEBIAN_FRONTEND=noninteractive pam-auth-update

PWQ_CONF="/etc/security/pwquality.conf"

# Strip any search characters in the key so it can be safely replaced.
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^ucredit")

# Format "ucredit = -1"
printf -v formatted_output "%s = %s" "$stripped_key" "$var_password_pam_ucredit"

# If the key exists, change it. Otherwise, append it.
if LC_ALL=C grep -q -m 1 -i -e "^ucredit\\>" "$PWQ_CONF" 2>/dev/null; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^ucredit\\>.*/$escaped_formatted_output/gi" "$PWQ_CONF"
else
    if [[ -s "$PWQ_CONF" ]] && [[ -n "$(tail -c 1 -- "$PWQ_CONF" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "$PWQ_CONF"
    fi
    printf '%s\n' "$formatted_output" >> "$PWQ_CONF"
fi
