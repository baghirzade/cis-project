#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_bashrc"
TITLE="Set umask 027 for users in /etc/bash.bashrc"

# Remediation is applicable only if bash is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'bash' 2>/dev/null | grep -q '^installed$'; then
    echo "Remediation not applicable: bash package is not installed." >&2
    exit 0
fi

var_accounts_user_umask='027'
TARGET_FILE="/etc/bash.bashrc"

if [ ! -f "$TARGET_FILE" ]; then
    # Create file if missing
    touch "$TARGET_FILE"
fi

# Backup first
cp "$TARGET_FILE" "${TARGET_FILE}.bak.$(date +%Y%m%d%H%M%S)"

# If an uncommented umask exists, replace its value.
# Otherwise, append a new line.
if grep -q "^[^#]*\bumask" "$TARGET_FILE"; then
    sed -i -E -e "s/^([^#]*\bumask)[[:space:]]+[[:digit:]]+/\1 $var_accounts_user_umask/g" "$TARGET_FILE"
    if [ $? -ne 0 ]; then
        echo "ERROR: Failed to update existing umask in $TARGET_FILE" >&2
        exit 1
    fi
else
    echo "umask $var_accounts_user_umask" >> "$TARGET_FILE"
fi

echo "Remediation applied: set umask $var_accounts_user_umask in $TARGET_FILE"
