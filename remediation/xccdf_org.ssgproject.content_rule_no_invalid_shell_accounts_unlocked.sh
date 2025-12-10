#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_invalid_shell_accounts_unlocked"

# If /etc/shells is missing, assume not applicable
if [ ! -f /etc/shells ]; then
    >&2 echo "Remediation for ${RULE_ID} not applied: /etc/shells not found"
    exit 0
fi

mapfile -t bad_users < <(
    awk -F: '{print $1 ":" $7}' /etc/passwd | while IFS=: read -r user shell; do
        [ -z "$shell" ] && continue

        if ! grep -qxF "$shell" /etc/shells 2>/dev/null; then
            pw_field=$(awk -F: -v u="$user" '$1 == u { print $2 }' /etc/shadow 2>/dev/null)

            if [ -n "$pw_field" ] && [[ "$pw_field" != '!'* && "$pw_field" != '*'* ]]; then
                echo "$user"
            fi
        fi
    done
)

# If nothing to fix, exit silently (framework already prints summary)
if [ "${#bad_users[@]}" -eq 0 ]; then
    exit 0
fi

for user in "${bad_users[@]}"; do
    if passwd -l "$user" >/dev/null 2>&1; then
        >&2 echo "Locked account '${user}' because it has an invalid shell not listed in /etc/shells"
    else
        >&2 echo "Failed to lock account '${user}'"
        exit 1
    fi
done

exit 0
