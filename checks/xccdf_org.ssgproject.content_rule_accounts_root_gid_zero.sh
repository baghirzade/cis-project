#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_root_gid_zero"

if [[ ! -r /etc/passwd ]]; then
    echo "FAIL|${RULE_ID}|/etc/passwd is not readable; cannot verify root GID"
    exit 0
fi

root_line="$(awk -F: '$1=="root"' /etc/passwd || true)"

if [[ -z "$root_line" ]]; then
    echo "FAIL|${RULE_ID}|root account is missing in /etc/passwd"
    exit 0
fi

root_gid="$(printf '%s\n' "$root_line" | awk -F: '{print $4}')"

if [[ -z "$root_gid" ]]; then
    echo "FAIL|${RULE_ID}|Unable to determine primary GID for root account"
    exit 0
fi

if [[ "$root_gid" == "0" ]]; then
    echo "OK|${RULE_ID}|root account has primary group ID 0 (root group)"
else
    echo "WARN|${RULE_ID}|root account has primary GID ${root_gid}, expected 0 (root group)"
fi

exit 0
