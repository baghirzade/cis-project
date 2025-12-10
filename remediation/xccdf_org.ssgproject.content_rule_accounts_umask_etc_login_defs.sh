#!/bin/bash
RULE_ID="xccdf_org.ssgproject.content_rule_accounts_umask_etc_login_defs"
TITLE="Set UMASK 027 in /etc/login.defs for new accounts"

# Remediation is applicable only if 'login' is installed
if ! dpkg-query --show --showformat='${db:Status-Status}' 'login' 2>/dev/null | grep -q '^installed$'; then
    echo "Remediation not applicable: 'login' package is not installed." >&2
    exit 0
fi

var_accounts_user_umask='027'
LOGIN_DEFS="/etc/login.defs"

if [ ! -f "$LOGIN_DEFS" ]; then
    touch "$LOGIN_DEFS"
fi

# Backup file
cp "$LOGIN_DEFS" "${LOGIN_DEFS}.bak.$(date +%Y%m%d%H%M%S)"

# Prepare stripped key and formatted output (same logic as SCAP snippet)
stripped_key=$(sed 's/[\^=\$,;+]*//g' <<< "^UMASK")
printf -v formatted_output "%s %s" "$stripped_key" "$var_accounts_user_umask"

# If UMASK exists, replace; otherwise append
if LC_ALL=C grep -q -m 1 -i -e "^UMASK\\>" "$LOGIN_DEFS"; then
    escaped_formatted_output=$(sed -e 's|/|\\/|g' <<< "$formatted_output")
    LC_ALL=C sed -i --follow-symlinks "s/^UMASK\\>.*/$escaped_formatted_output/gi" "$LOGIN_DEFS"
else
    if [[ -s "$LOGIN_DEFS" ]] && [[ -n "$(tail -c 1 -- "$LOGIN_DEFS" || true)" ]]; then
        LC_ALL=C sed -i --follow-symlinks '$a'\\ "$LOGIN_DEFS"
    fi
    printf '%s\n' "$formatted_output" >> "$LOGIN_DEFS"
fi

echo "Remediation applied: UMASK set to $var_accounts_user_umask in $LOGIN_DEFS"
