#!/usr/bin/env bash
# Check that all password hashes are stored in /etc/shadow and not in /etc/passwd

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_all_shadowed"

# Basic sanity check
if [[ ! -r /etc/passwd ]]; then
    echo "FAIL|${RULE_ID}|/etc/passwd is not readable"
    exit 1
fi

# Find accounts whose password field in /etc/passwd is not a shadow placeholder
# Allowed placeholders: x, !, *, !!, !*, -
NON_SHADOWED_USERS=$(
    awk -F: '($2 !~ /^(!|x|\*|!!|!\*|-)$/ && $2 != "") {print $1}' /etc/passwd
)

if [[ -z "${NON_SHADOWED_USERS}" ]]; then
    echo "OK|${RULE_ID}|All accounts use shadowed passwords (no hashes in /etc/passwd)"
else
    # List of users with non-shadowed password fields
    echo "WARN|${RULE_ID}|Found accounts with password hashes or cleartext passwords in /etc/passwd: ${NON_SHADOWED_USERS}"
fi
