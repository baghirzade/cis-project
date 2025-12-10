#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_user_interactive_home_directory_exists"

# mkhomedir_helper binary-ni tapaq
MKHOMEDIR_HELPER="$(command -v mkhomedir_helper || echo "/usr/sbin/mkhomedir_helper")"

if [ ! -x "$MKHOMEDIR_HELPER" ]; then
    echo "ERROR|${RULE_ID}|mkhomedir_helper not found or not executable"
    exit 1
fi

# UID >= 1000 və UID != 65534 olan istifadəçilər
awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$6}' /etc/passwd | \
while IFS=: read -r user home; do
    # Home boşdursa, keç
    [ -n "$home" ] || continue

    # Artıq mövcuddursa, toxunma
    if [ -d "$home" ]; then
        continue
    fi

    # Home kataloqunu yarat
    "$MKHOMEDIR_HELPER" "$user" 0077
done

exit 0
