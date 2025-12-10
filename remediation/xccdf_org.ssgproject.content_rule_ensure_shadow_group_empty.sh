#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_ensure_shadow_group_empty"

(>&2 echo "Remediating: ${RULE_ID}")

GROUP_FILE="/etc/group"

if [ ! -w "$GROUP_FILE" ]; then
    (>&2 echo "Cannot remediate: /etc/group is not writable")
    exit 1
fi

# Remove all members from the 'shadow' group (4th field)
sed -ri 's/^(shadow:[^:]*:[^:]*:)([^:]+)$/\1/' "$GROUP_FILE"

exit 0
