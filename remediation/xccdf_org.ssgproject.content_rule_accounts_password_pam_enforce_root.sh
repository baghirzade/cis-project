#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_enforce_root"
(>&2 echo "Remediating: ${RULE_ID}")

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo 'Remediation is not applicable, libpwquality1 is not installed'
    exit 0
fi

PWQ_CONF="/etc/security/pwquality.conf"

# Ensure file exists
if [ ! -e "$PWQ_CONF" ] ; then
    touch "$PWQ_CONF"
fi

# Make sure file has a trailing newline
sed -i -e '$a\' "$PWQ_CONF"

# Remove any existing enforce_for_root definitions (case-insensitive)
LC_ALL=C sed -i "/^[[:space:]]*enforce_for_root/Id" "$PWQ_CONF"

# Append canonical enforce_for_root line
printf '%s\n' "enforce_for_root" >> "$PWQ_CONF"
