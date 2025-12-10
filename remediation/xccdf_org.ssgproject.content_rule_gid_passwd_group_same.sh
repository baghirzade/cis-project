#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_gid_passwd_group_same"

PASSWD_FILE="/etc/passwd"
GROUP_FILE="/etc/group"

if [[ ! -r "$PASSWD_FILE" ]] || [[ ! -r "$GROUP_FILE" ]]; then
    >&2 echo "Remediation for ${RULE_ID}: cannot read /etc/passwd or /etc/group"
    exit 1
fi

# Build set of existing GIDs and group names
declare -A GROUP_GIDS
declare -A GROUP_NAME_BY_GID
declare -A GROUP_GID_BY_NAME

while IFS=: read -r gname x gid members; do
    [[ -z "$gid" ]] && continue
    if [[ "$gid" =~ ^[0-9]+$ ]]; then
        GROUP_GIDS["$gid"]=1
        GROUP_NAME_BY_GID["$gid"]="$gname"
        GROUP_GID_BY_NAME["$gname"]="$gid"
    fi
done < "$GROUP_FILE"

# Iterate over users and fix missing group IDs
while IFS=: read -r uname x uid gid gecos home shell; do
    # Only consider numeric gids
    if [[ -z "$gid" || ! "$gid" =~ ^[0-9]+$ ]]; then
        continue
    fi

    # If GID already exists in /etc/group, nothing to do for this user
    if [[ -n "${GROUP_GIDS[$gid]+x}" ]]; then
        continue
    fi

    # We need to create a group for this gid
    new_group_name="$uname"

    if getent group "$new_group_name" >/dev/null 2>&1; then
        # Name is used with a different gid – choose a safe alternative
        new_group_name="${uname}_gid_${gid}"
        # If that also exists, keep appending suffix
        suffix=1
        while getent group "$new_group_name" >/dev/null 2>&1; do
            new_group_name="${uname}_gid_${gid}_${suffix}"
            suffix=$((suffix+1))
        done
    fi

    # Finally create the group
    if ! getent group "$gid" >/dev/null 2>&1; then
        groupadd -g "$gid" "$new_group_name"
    fi

done < "$PASSWD_FILE"

exit 0
