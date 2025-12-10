#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_dictcheck"

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

REQUIRED_MIN_VALUE=1   # dictcheck must be >= 1 (dictionary check enabled)

# 1) libpwquality1 installed?
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpwquality1' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpwquality1 is not installed (control not applicable)"
    exit 0
fi

PWQ_CONF="/etc/security/pwquality.conf"

# 2) Config file exists?
if [ ! -f "$PWQ_CONF" ]; then
    print_result "WARN" "/etc/security/pwquality.conf does not exist; dictcheck is not configured"
    exit 0
fi

# 3) Read dictcheck line
line="$(grep -Ei '^[[:space:]]*dictcheck[[:space:]]*=' "$PWQ_CONF" | tail -n 1 || true)"

if [ -z "$line" ]; then
    print_result "WARN" "dictcheck is not set in /etc/security/pwquality.conf"
    exit 0
fi

# 4) Extract value (first token after '=')
value="$(echo "$line" | sed -E 's/^[[:space:]]*dictcheck[[:space:]]*=[[:space:]]*//; s/[[:space:]].*$//')"

if ! [[ "$value" =~ ^-?[0-9]+$ ]]; then
    print_result "WARN" "dictcheck value in /etc/security/pwquality.conf is not numeric: '$value'"
    exit 0
fi

# 5) Evaluate policy
if [ "$value" -ge "$REQUIRED_MIN_VALUE" ]; then
    print_result "OK" "dictcheck is set to ${value} (dictionary check enabled; compliant)"
else
    print_result "WARN" "dictcheck is set to ${value} (must be >= ${REQUIRED_MIN_VALUE} to enforce dictionary check)"
fi
