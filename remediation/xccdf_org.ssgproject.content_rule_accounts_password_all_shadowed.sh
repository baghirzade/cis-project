#!/usr/bin/env bash
# Remediate: ensure all passwords are shadowed (no password hashes in /etc/passwd)

set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_all_shadowed"

# Sanity checks
if [[ ! -r /etc/passwd ]] || [[ ! -w /etc/passwd ]]; then
    >&2 echo "Remediation not possible: /etc/passwd is not readable/writable"
    exit 1
fi

if [[ ! -r /etc/shadow ]] || [[ ! -w /etc/shadow ]]; then
    >&2 echo "Remediation not possible: /etc/shadow is not readable/writable"
    exit 1
fi

# Backup files with timestamp
TS="$(date +%Y%m%d-%H%M%S)"
cp -p /etc/passwd /etc/passwd.bak-"${RULE_ID}-${TS}"
cp -p /etc/shadow /etc/shadow.bak-"${RULE_ID}-${TS}"

# Find accounts whose password field in /etc/passwd is not a shadow placeholder
# Allowed placeholders: x, !, *, !!, !*, -
awk -F: '($2 !~ /^(!|x|\*|!!|!\*|-)$/ && $2 != "") {print $1":"$2}' /etc/passwd | \
while IFS=: read -r USER PASS_FIELD; do
    # Skip empty username just in case
    [[ -z "${USER}" ]] && continue

    # Try to find corresponding shadow entry
    SHADOW_LINE="$(grep -E "^${USER}:" /etc/shadow || true)"

    if [[ -n "${SHADOW_LINE}" ]]; then
        # User already has a shadow entry
        SHADOW_REST="$(echo "${SHADOW_LINE}" | cut -d: -f3- )"
        SHADOW_PASS="$(echo "${SHADOW_LINE}" | cut -d: -f2 )"

        # If /etc/passwd field looks like a hash ($id$...) and shadow pass is empty/placeholder,
        # move the hash to /etc/shadow.
        if [[ "${PASS_FIELD}" =~ ^\$[0-9A-Za-z]+\$ ]] && [[ -z "${SHADOW_PASS}" || "${SHADOW_PASS}" =~ ^[!*]+$ ]]; then
            NEW_SHADOW_LINE="${USER}:${PASS_FIELD}:${SHADOW_REST}"
            sed -i "s|^${USER}:.*|${NEW_SHADOW_LINE}|" /etc/shadow
        fi
    else
        # No shadow entry exists for this user; create one.
        # If PASS_FIELD looks like a hash, reuse it, otherwise lock the account.
        if [[ "${PASS_FIELD}" =~ ^\$[0-9A-Za-z]+\$ ]]; then
            NEW_SHADOW_PASS="${PASS_FIELD}"
        else
            NEW_SHADOW_PASS="!"
        fi

        # lastchg (field 3) can be set to current day number since epoch/86400
        # but for simplicity use 0, admin can adjust later.
        echo "${USER}:${NEW_SHADOW_PASS}:0:0:99999:7:::" >> /etc/shadow
    fi

    # Finally, set /etc/passwd password field to 'x'
    sed -i "s|^${USER}:[^:]*:|${USER}:x:|" /etc/passwd
done

exit 0
