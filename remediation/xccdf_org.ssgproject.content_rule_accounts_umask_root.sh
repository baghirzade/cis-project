#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_root"
TITLE="Set umask 0027 in root shell init files"

# Remediation is applicable only when bash is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'bash' 2>/dev/null | grep -q '^installed$'; then
    echo "Remediation not applicable: 'bash' package is not installed." >&2
    exit 0
fi

TARGET_UMASK="0027"
files=("/root/.bashrc" "/root/.profile")

for file in "${files[@]}"; do
    # Only touch files that exist
    [ -f "$file" ] || continue

    if grep -qE '^[^#]*\bumask[[:space:]]+[0-7]{3}' "$file"; then
        # Normalize any existing uncommented umask in the file to 0027
        sed -i -E -e "s/^([^#]*\bumask)[[:space:]]+[0-7]{3}/\1 $TARGET_UMASK/g" "$file"
    else
        # No umask present -> append one at the end
        echo "umask $TARGET_UMASK" >> "$file"
    fi
done

echo "Remediation applied: root umask set to $TARGET_UMASK in /root/.bashrc and /root/.profile (where present)."
