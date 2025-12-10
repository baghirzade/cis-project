#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_set_max_life_existing"

(>&2 echo "Remediating: ${RULE_ID}")

SHADOW_FILE="/etc/shadow"
MAX_DAYS="365"

# chage must exist
if ! command -v chage >/dev/null 2>&1; then
    (>&2 echo "Cannot remediate: 'chage' command not found")
    exit 1
fi

if [ ! -r "$SHADOW_FILE" ]; then
    (>&2 echo "Cannot remediate: ${SHADOW_FILE} is not readable")
    exit 1
fi

remediation_failed=0

while IFS= read -r user; do
    # Skip empty lines just in case
    [ -z "$user" ] && continue

    if ! chage -M "$MAX_DAYS" "$user" 2>/dev/null; then
        (>&2 echo "Failed to set max password age (${MAX_DAYS} days) for user: ${user}")
        remediation_failed=1
    else
        (>&2 echo "Set max password age (${MAX_DAYS} days) for user: ${user}")
    fi
done < <(awk -F: -v var="$MAX_DAYS" '
    /^[^:]+:[^!*]/ && ($5 == "" || $5 > var) { print $1 }
' "$SHADOW_FILE")

exit "$remediation_failed"
