#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_dcredit"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

REQUIRED_MAX_VALUE=-1   # dcredit must be <= -1 (require at least one digit)

# 1) libpwquality1 installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpwquality1 is not installed (control not applicable)"
    exit 0
fi

PWQ_CONF="/etc/security/pwquality.conf"

# 2) Config file exists?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "/etc/security/pwquality.conf does not exist; dcredit is not configured"
    exit 0
fi

# 3) Read dcredit line
line="$(grep -Ei '^[[:space:]]*dcredit[[:space:]]*=' "$PWQ_CONF" | tail -n 1 || true)"

if [ -z "$line" ]; then
    print_result "WARN" "dcredit is not set in /etc/security/pwquality.conf"
    exit 0
fi

# 4) Extract value (first token after '=')
value="$(echo "$line" | sed -E 's/^[[:space:]]*dcredit[[:space:]]*=[[:space:]]*//; s/[[:space:]].*$//')"

if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
    print_result "WARN" "dcredit value in /etc/security/pwquality.conf is not numeric: '$value'"
    exit 0
fi

# 5) Evaluate policy
if [ "$value" -le "$REQUIRED_MAX_VALUE" ]; then
    print_result "OK" "dcredit is set to ${value} (at least one digit required; compliant)"
else
    print_result "WARN" "dcredit is set to ${value} (required <= ${REQUIRED_MAX_VALUE} to enforce at least one digit)"
fi
