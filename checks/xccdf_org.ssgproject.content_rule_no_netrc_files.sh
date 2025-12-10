#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_netrc_files"

# Basic sanity check
if [[ ! -r /etc/passwd ]]; then
    echo "FAIL|${RULE_ID}|/etc/passwd is not readable; cannot enumerate local users"
    exit 0
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

found_entries=()

for uh in "${USER_HOMES[@]}"; do
    user="${uh%%:*}"
    home="${uh#*:}"
    f="${home}/.netrc"
    if [[ -f "$f" ]]; then
        found_entries+=("${user}:${f}")
    fi
done

if [[ "${#found_entries[@]}" -eq 0 ]]; then
    echo "OK|${RULE_ID}|No .netrc files present in local user home directories"
else
    list_csv="$(printf '%s,' "${found_entries[@]}" | sed 's/,$//')"
    echo "WARN|${RULE_ID}|Found .netrc file(s): ${list_csv}"
fi

exit 0
