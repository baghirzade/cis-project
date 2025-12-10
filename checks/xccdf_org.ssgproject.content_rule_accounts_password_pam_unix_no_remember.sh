#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_unix_no_remember"

# Check applicability: libpam-runtime must be installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    echo "NOTAPPL|${RULE_ID}|Package 'libpam-runtime' is not installed (control not applicable)"
    exit 0
fi

CONFIG_FILES=(
    "/usr/share/pam-configs/cac_unix"
    "/usr/share/pam-configs/unix"
)

checked_any="false"
found_violation="false"

for f in "${CONFIG_FILES[@]}"; do
    if [[ -f "$f" ]]; then
        checked_any="true"
        if grep -Eq 'pam_unix\.so.*remember=' "$f"; then
            found_violation="true"
        fi
    fi
done

if [[ "$checked_any" != "true" ]]; then
    # No unix/cac_unix pam-config found – unusual but not a script error
    echo "WARN|${RULE_ID}|No pam-config file (cac_unix or unix) found to check for pam_unix remember= option"
    exit 0
fi

if [[ "$found_violation" == "true" ]]; then
    echo "WARN|${RULE_ID}|pam_unix is configured with remember= option (should be removed; use pam_pwhistory instead)"
else
    echo "OK|${RULE_ID}|pam_unix is not configured with remember= option"
fi
