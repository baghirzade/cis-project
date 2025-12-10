#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_invalid_shell_accounts_unlocked"

# If /etc/shells is missing, we cannot reliably validate shells
if [ ! -f /etc/shells ]; then
    echo "NOTAPPL|${RULE_ID}|/etc/shells not found (cannot validate login shells)"
    exit 0
fi

mapfile -t bad_users < <(
    awk -F: '{print $1 ":" $7}' /etc/passwd | while IFS=: read -r user shell; do
        # Skip accounts without a shell field
        [ -z "$shell" ] && continue

        # If the shell is not listed in /etc/shells, it is considered invalid
        if ! grep -qxF "$shell" /etc/shells 2>/dev/null; then
            # Check if account is unlocked in /etc/shadow
            pw_field=$(awk -F: -v u="$user" '$1 == u { print $2 }' /etc/shadow 2>/dev/null)

            # Consider locked if password field starts with ! or *, or is empty
            if [ -n "$pw_field" ] && [[ "$pw_field" != '!'* && "$pw_field" != '*'* ]]; then
                echo "$user"
            fi
        fi
    done
)

if [ "${#bad_users[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|No unlocked accounts with invalid shells found"
else
    echo "WARN|${RULE_ID}|Unlocked accounts with invalid shells found: ${bad_users[*]}"
fi

exit 0
