#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_no_shelllogin_for_systemaccounts"

# /etc/passwd yoxdursa, heç nə etmirik
if [ ! -f /etc/passwd ]; then
    exit 0
fi

# İstifadə olunacaq non-login shell-i seçək
if command -v nologin >/dev/null 2>&1; then
    NOLOGIN_SHELL="$(command -v nologin)"
elif [ -x /usr/sbin/nologin ]; then
    NOLOGIN_SHELL="/usr/sbin/nologin"
elif [ -x /sbin/nologin ]; then
    NOLOGIN_SHELL="/sbin/nologin"
else
    NOLOGIN_SHELL="/bin/false"
fi

# UID < 1000, root olmayan və login shell-i icazə verilən siyahıda olmayan hesablar
mapfile -t bad_accounts < <(
    awk -F: '
        ($3 < 1000 && $1 != "root" &&
         $7 !~ /^(\/sbin\/nologin|\/usr\/sbin\/nologin|\/bin\/false|\/sbin\/shutdown|\/sbin\/halt|\/bin\/sync)$/) {
            print $1
        }' /etc/passwd
)

# Hər biri üçün shell-i NOLOGIN_SHELL ilə əvəz et
for acct in "${bad_accounts[@]}"; do
    usermod -s "$NOLOGIN_SHELL" "$acct" >/dev/null 2>&1
done

exit 0
