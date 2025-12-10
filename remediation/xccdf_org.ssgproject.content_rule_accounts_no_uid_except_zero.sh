#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_no_uid_except_zero"

if [[ ! -r /etc/passwd ]]; then
    >&2 echo "Remediation for ${RULE_ID} failed: /etc/passwd is not readable"
    exit 1
fi

mapfile -t non_root_uid0 < <(awk -F: '$3 == 0 && $1 != "root" { print $1 }' /etc/passwd)

if [[ "${#non_root_uid0[@]}" -eq 0 ]]; then
    # Nothing to remediate
    exit 0
fi

for user in "${non_root_uid0[@]}"; do
    if id "$user" &>/dev/null; then
        # Lock the account so it cannot be used
        if ! passwd -l -- "$user" >/dev/null 2>&1; then
            >&2 echo "Remediation for ${RULE_ID}: failed to lock account '${user}' with UID 0"
            exit 1
        fi
    else
        >&2 echo "Remediation for ${RULE_ID}: account '${user}' no longer exists, skipping"
    fi
done

exit 0
