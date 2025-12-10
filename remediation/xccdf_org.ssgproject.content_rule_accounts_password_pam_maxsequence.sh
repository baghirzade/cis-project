#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_maxsequence"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only if libpwquality1 is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpwquality1 is not installed'
    exit 0
fi

PWQ_CONF="/etc/security/pwquality.conf"
conf_name="cac_pwquality"
conf_path="/usr/share/pam-configs"

# Ensure pam-config for pwquality exists (so pam_pwquality is actually used)
if [ ! -f "${conf_path}/${conf_name}" ]; then
    cat << EOF_INNER > "${conf_path}/${conf_name}"
Name: Pwquality password strength checking
Default: yes
Priority: 1025
Conflicts: cracklib, pwquality
Password-Type: Primary
Password:
    requisite                   pam_pwquality.so
EOF_INNER
    DEBIAN_FRONTEND=noninteractive pam-auth-update
fi

# Ensure pwquality.conf exists
if [ ! -e "$PWQ_CONF" ]; then
    touch "$PWQ_CONF"
fi

# Ensure file has a trailing newline
sed -i -e '$a\' "$PWQ_CONF"

var_password_pam_maxsequence='3'
formatted_output="maxsequence = ${var_password_pam_maxsequence}"

# If the key exists, replace it; otherwise append
if LC_ALL=C grep -qi -m 1 '^[[:space:]]*maxsequence[[:space:]]*=' "$PWQ_CONF"; then
    escaped_formatted_output=$(printf '%s\n' "$formatted_output" | sed -e 's|/|\\/|g')
    LC_ALL=C sed -i --follow-symlinks "s/^[[:space:]]*maxsequence[[:space:]]*=.*/${escaped_formatted_output}/I" "$PWQ_CONF"
else
    printf '%s\n' "$formatted_output" >> "$PWQ_CONF"
fi
