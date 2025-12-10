#!/usr/bin/env bash
# Remediate: ensure password last change date is not in the future and is valid

set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_last_change_is_in_past"

# Sanity checks
if [[ ! -r /etc/shadow ]] || [[ ! -w /etc/shadow ]]; then
    >&2 echo "Remediation not possible: /etc/shadow is not readable/writable"
    exit 1
fi

# Backup with timestamp
TS="$(date +%Y%m%d-%H%M%S)"
cp -p /etc/shadow /etc/shadow.bak-"${RULE_ID}-${TS}"

# Today in days since epoch
TODAY_DAYS=$(( $(date +%s) / 86400 ))

TMP_FILE="$(mktemp)"

awk -F: -vOFS=: -v today="$TODAY_DAYS" '
{
    user = $1;
    pass = $2;
    last = $3;

    # Only touch accounts with real hashes (start with $)
    if (pass ~ /^\$/) {
        # If last change is empty, non-numeric, or in the future, set to today
        if (last == "" || last !~ /^[0-9]+$/ || last > today) {
            $3 = today;
        }
    }

    print
}
' /etc/shadow > "$TMP_FILE"

# Overwrite /etc/shadow preserving original perms/ownership
cat "$TMP_FILE" > /etc/shadow
rm -f "$TMP_FILE"

exit 0
