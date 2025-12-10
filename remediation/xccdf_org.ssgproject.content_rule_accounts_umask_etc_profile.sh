#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_profile"
TITLE="Set umask 027 in /etc/profile and /etc/profile.d scripts"

# Remediation is applicable only when bash is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'bash' 2>/dev/null | grep -q '^installed$'; then
    echo "Remediation not applicable: 'bash' package is not installed." >&2
    exit 0
fi

var_accounts_user_umask='027'

# Collect profile.d files as in upstream snippet
readarray -t profile_files < <(find /etc/profile.d/ -type f -name '*.sh' -or -name 'sh.local' 2>/dev/null)

# Update existing umask settings in /etc/profile.d/*.sh and sh.local
for file in "${profile_files[@]}" /etc/profile; do
    [ -f "$file" ] || continue
    # If file contains an uncommented 'umask', normalize it to the required value
    if grep -qE '^[^#]*umask' "$file"; then
        sed -i -E "s/^(\s*umask\s*)[0-7]+/\1$var_accounts_user_umask/g" "$file"
    fi
done

# If there is still no umask anywhere in /etc/profile*, append it to /etc/profile
if ! grep -qrE '^[^#]*umask' /etc/profile* 2>/dev/null; then
    echo "umask $var_accounts_user_umask" >> /etc/profile
fi

echo "Remediation applied: umask set to $var_accounts_user_umask in /etc/profile and /etc/profile.d scripts (where present)."
