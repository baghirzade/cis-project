#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwquality_enabled"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only if libpam-runtime is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpam-runtime is not installed'
    exit 0
fi

conf_name="cac_pwquality"
conf_path="/usr/share/pam-configs"

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
