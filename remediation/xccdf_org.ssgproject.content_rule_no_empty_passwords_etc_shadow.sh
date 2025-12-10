#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_empty_passwords_etc_shadow"

# Remediation is applicable only in certain platforms
if ! dpkg-query --show --showformat='${db:Status-Status}' 'linux-base' 2>/dev/null | grep -q '^installed$'; then
    >&2 echo "Remediation is not applicable for ${RULE_ID} (linux-base not installed)"
    exit 0
fi

SHADOW_FILE="/etc/shadow"

if [[ ! -r "$SHADOW_FILE" ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: cannot read /etc/shadow"
    exit 1
fi

mapfile -t users_with_empty_pass < <(awk -F: '$2 == "" {print $1}' "$SHADOW_FILE")

if [[ ${#users_with_empty_pass[@]} -eq 0 ]]; then
    # Nothing to fix
    exit 0
fi

for user_with_empty_pass in "${users_with_empty_pass[@]}"; do
    # Only attempt to lock if account exists
    if id "$user_with_empty_pass" >/dev/null 2>&1; then
        if ! passwd -l "$user_with_empty_pass" >/dev/null 2>&1; then
            >&2 echo "Remediation for ${RULE_ID}: failed to lock account '$user_with_empty_pass'"
        fi
    else
        >&2 echo "Remediation for ${RULE_ID}: user '$user_with_empty_pass' not found in system accounts"
    fi
done

exit 0
