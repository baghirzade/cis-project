#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_account_disable_post_pw_expiration"
TARGET_DAYS=45

print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# Check if 'login' package is installed (control applicability)
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "Package 'login' is not installed; control not applicable on this system"
    exit 0
fi

USERADD_DEFAULTS="/etc/default/useradd"

if [ ! -f "$USERADD_DEFAULTS" ]; then
    print_result "FAIL" "$USERADD_DEFAULTS is missing; cannot verify INACTIVE setting"
    exit 1
fi

# Read INACTIVE= value (ignore comments and spaces)
inactive_line="$(grep -E '^[[:space:]]*INACTIVE[[:space:]]*=' "$USERADD_DEFAULTS" || true)"

if [ -z "$inactive_line" ]; then
    print_result "WARN" "INACTIVE is not set in $USERADD_DEFAULTS (accounts may never be disabled after password expiration)"
    exit 0
fi

inactive_value="$(echo "$inactive_line" | cut -d '=' -f 2 | tr -d '[:space:]')"

# Validate numeric
if ! [[ "$inactive_value" =~ ^-?[0-9]+$ ]]; then
    print_result "WARN" "INACTIVE in $USERADD_DEFAULTS is set to a non-numeric value '$inactive_value'"
    exit 0
fi

# -1 typically means 'never disable'
if [ "$inactive_value" -lt 0 ]; then
    print_result "WARN" "INACTIVE in $USERADD_DEFAULTS is set to $inactive_value (accounts are never disabled after password expiration)"
    exit 0
fi

if [ "$inactive_value" -le "$TARGET_DAYS" ]; then
    print_result "OK" "Account inactivity period after password expiration is set to $inactive_value days (<= $TARGET_DAYS)"
else
    print_result "WARN" "INACTIVE in $USERADD_DEFAULTS is set to $inactive_value days (> $TARGET_DAYS)"
fi
