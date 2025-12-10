#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_groups_no_zero_gid_except_root"

# Only 'root' group is allowed to have GID 0
mapfile -t bad_groups < <(awk -F: '$3 == 0 && $1 != "root" { print $1 }' /etc/group)

if [ "${#bad_groups[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|Only 'root' group has GID 0"
else
    echo "WARN|${RULE_ID}|Non-root groups with GID 0 found: ${bad_groups[*]}"
fi

exit 0
