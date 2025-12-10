#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_user_dot_group_ownership"

# UID >= 1000 və UID != 65534 (nobody) olan istifadəçilər üçün
awk -F: '($3 >= 1000 && $3 != 65534) {print $4":"$6}' /etc/passwd | \
while IFS=: read -r gid home; do
    # Home kataloq mövcud deyilsə, keç
    [ -d "$home" ] || continue

    # Home altında birinci səviyyədəki dotfile-ların group-unu düzəlt
    find -P "$home" -maxdepth 1 -type f -name ".[^.]*" \
        -exec chgrp -f --no-dereference -- "$gid" {} \; 2>/dev/null
done

exit 0
