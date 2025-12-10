#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_ucredit"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

PWQ_CONF="/etc/security/pwquality.conf"

# 1) libpwquality1 installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpwquality1 is not installed (control not applicable)"
    exit 0
fi

# 2) Config file exists?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "$PWQ_CONF does not exist; 'ucredit' setting is not defined"
    exit 0
fi

# 3) Look for 'ucredit = <value>'
ucredit_line=$(grep -iE '^[[:space:]]*ucredit[[:space:]]*=' "$PWQ_CONF" || true)

if [ -z "$ucredit_line" ]; then
    print_result "WARN" "'ucredit' is not configured in $PWQ_CONF"
    exit 0
fi

# Extract value part
ucredit_value=$(echo "$ucredit_line" | awk -F'=' '{gsub(/[[:space:]]/, "", $2); print $2}')

if [ "$ucredit_value" = "-1" ]; then
    print_result "OK" "'ucredit' is configured as -1 in $PWQ_CONF"
else
    print_result "WARN" "'ucredit' is set to '$ucredit_value' (expected -1) in $PWQ_CONF"
fi
