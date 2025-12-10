#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_no_forward_files"

if [[ ! -r /etc/passwd ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: /etc/passwd is not readable"
    exit 1
fi

declare -a USER_HOMES=()

# Local users with UID >= 1000 and not nobody
while IFS=: read -r user _ uid _ _ home _; do
    if [[ "$uid" -ge 1000 && "$user" != "nobody" && -n "$home" && -d "$home" ]]; then
        USER_HOMES+=("${user}:${home}")
    fi
done < /etc/passwd

# Add root explicitly if present
root_entry="$(getent passwd root || true)"
if [[ -n "$root_entry" ]]; then
    root_home="$(echo "$root_entry" | cut -d: -f6)"
    if [[ -n "$root_home" && -d "$root_home" ]]; then
        USER_HOMES+=("root:${root_home}")
    fi
fi

for uh in "${USER_HOMES[@]}"; do
    user="${uh%%:*}"
    home="${uh#*:}"
    f="${home}/.forward"
    if [[ -f "$f" ]]; then
        rm -f -- "$f" || {
            >&2 echo "Remediation for ${RULE_ID}: failed to remove ${f} (user ${user})"
            exit 1
        }
    fi
done

exit 0
