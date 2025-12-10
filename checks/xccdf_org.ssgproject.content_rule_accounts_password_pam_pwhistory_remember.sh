#!/usr/bin/env bash
set -euo pipefail

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_password_pam_pwhistory_remember"
REQUIRED_REMEMBER=24
CONF_FILE="/usr/share/pam-configs/cac_pwhistory"

# Helper: print result line
print_result() {
    local status="$1"
    local message="$2"
    echo "${status}|${RULE_ID}|${message}"
}

# 1. Check libpam-runtime presence
if ! dpkg-query --show --showformat='${db:Status-Status}' 'libpam-runtime' 2>/dev/null | grep -q '^installed$'; then
    print_result "NOTAPPL" "libpam-runtime is not installed (control not applicable)"
    exit 0
fi

# 2. If authselect is present, we don't parse its custom profiles (out of scope for now)
if command -v authselect >/dev/null 2>&1; then
    print_result "WARN" "System uses authselect; password history (remember=) is not validated by this checker"
    exit 0
fi

# 3. Check configuration file existence
if [ ! -f "$CONF_FILE" ]; then
    print_result "WARN" "pam_pwhistory configuration file $CONF_FILE is missing (password history enforcement not configured)"
    exit 0
fi

# 4. Extract remember values from pam_pwhistory lines
mapfile -t remember_vals < <(grep -E 'pam_pwhistory\.so' "$CONF_FILE" 2>/dev/null \
    | sed -n 's/.*remember=\([0-9]\+\).*/\1/p')

if [ "${#remember_vals[@]}" -eq 0 ]; then
    print_result "WARN" "pam_pwhistory is configured in $CONF_FILE but remember= is missing"
    exit 0
fi

# Find the minimum remember value (if multiple lines exist)
min_val="${remember_vals[0]}"
for v in "${remember_vals[@]}"; do
    if [ "$v" -lt "$min_val" ]; then
        min_val="$v"
    fi
done

if [ "$min_val" -lt "$REQUIRED_REMEMBER" ]; then
    print_result "WARN" "pam_pwhistory remember is set to $min_val (< ${REQUIRED_REMEMBER}) in $CONF_FILE"
    exit 0
fi

# 5. Ensure cac_pwhistory is enabled in PAM via pam-auth-update
if pam-auth-update --list 2>/dev/null | grep -q 'cac_pwhistory.*\[enabled\]'; then
    print_result "OK" "pam_pwhistory remember is set to ${min_val} (>= ${REQUIRED_REMEMBER}) and cac_pwhistory is enabled"
else
    print_result "WARN" "pam_pwhistory remember is correctly set (>= ${REQUIRED_REMEMBER}) but cac_pwhistory is not enabled in PAM"
fi
