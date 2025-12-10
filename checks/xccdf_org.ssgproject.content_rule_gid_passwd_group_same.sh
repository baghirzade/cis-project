#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_gid_passwd_group_same"

PASSWD_FILE="/etc/passwd"
GROUP_FILE="/etc/group"

if [[ ! -r "$PASSWD_FILE" ]] || [[ ! -r "$GROUP_FILE" ]]; then
    echo "FAIL|${RULE_ID}|Cannot read /etc/passwd or /etc/group"
    exit 0
fi

# Build set of valid GIDs from /etc/group
declare -A GROUP_GIDS
while IFS=: read -r gname x gid members; do
    [[ -z "$gid" ]] && continue
    if [[ "$gid" =~ ^[0-9]+$ ]]; then
        GROUP_GIDS["$gid"]=1
    fi
done < "$GROUP_FILE"

missing_users=()

while IFS=: read -r uname x uid gid gecos home shell; do
    # Only consider numeric gids
    if [[ -n "$gid" && "$gid" =~ ^[0-9]+$ ]]; then
        if [[ -z "${GROUP_GIDS[$gid]+x}" ]]; then
            missing_users+=("${uname}:${gid}")
        fi
    fi
done < "$PASSWD_FILE"

if [[ ${#missing_users[@]} -eq 0 ]]; then
    echo "OK|${RULE_ID}|All primary group IDs in /etc/passwd exist in /etc/group"
else
    # configuration issue, but script worked ⇒ WARN
    list=$(printf "%s " "${missing_users[@]}")
    echo "WARN|${RULE_ID}|Users with primary GIDs missing in /etc/group: ${list}"
fi

exit 0
