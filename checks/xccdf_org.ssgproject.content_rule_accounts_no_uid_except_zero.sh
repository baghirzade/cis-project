#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_no_uid_except_zero"

if [[ ! -r /etc/passwd ]]; then
    echo "FAIL|${RULE_ID}|/etc/passwd is not readable; cannot verify UID 0 accounts"
    exit 0
fi

# List all accounts with UID 0 except 'root'
mapfile -t non_root_uid0 < <(awk -F: '$3 == 0 && $1 != "root" { print $1 }' /etc/passwd)

if [[ "${#non_root_uid0[@]}" -eq 0 ]]; then
    echo "OK|${RULE_ID}|Only 'root' account has UID 0"
else
    list_csv="$(printf '%s,' "${non_root_uid0[@]}" | sed 's/,$//')"
    echo "WARN|${RULE_ID}|Found non-root account(s) with UID 0: ${list_csv}"
fi

exit 0
