#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_set_post_pw_existing"
(>&2 echo "Remediating: ${RULE_ID}")

SHADOW_FILE="/etc/shadow"
var_account_disable_post_pw_expiration='45'

if [ ! -r "$SHADOW_FILE" ]; then
    (>&2 echo "Cannot remediate: ${SHADOW_FILE} is not readable")
    exit 1
fi

# For each account where:
#  - password field has a hash (starts with '$')
#  - inactive field ($7) is empty or > var_account_disable_post_pw_expiration
# set inactive days using chage --inactive
while IFS= read -r user; do
    if id "$user" >/dev/null 2>&1; then
        chage --inactive "$var_account_disable_post_pw_expiration" "$user" || \
            (>&2 echo "Failed to set inactivity for user ${user}")
    else
        (>&2 echo "Skipping unknown user ${user}")
    fi
done < <(awk -F: -v var="$var_account_disable_post_pw_expiration" '
    ($2 ~ /^\$/) && (($7 == "") || ($7 > var)) { print $1 }
' "$SHADOW_FILE")

exit 0
