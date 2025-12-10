#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_user_interactive_home_directory_exists"

# UID >= 1000 və UID != 65534 olan istifadəçi + home
mapfile -t USERS < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$6}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No regular users with UID>=1000 found"
    exit 0
fi

missing_home=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user home <<< "$entry"

    # Home sahəsi boşdursa və ya root-dursa, bunu da problem sayaq
    if [ -z "$home" ] || [ "$home" = "/" ]; then
        missing_home+=("user=${user} home=${home:-<empty>}")
        continue
    fi

    if [ ! -d "$home" ]; then
        missing_home+=("user=${user} home=${home}")
    fi
done

if [ "${#missing_home[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All interactive users have an existing home directory"
else
    msg="Some interactive users do not have an existing home directory:"
    for e in "${missing_home[@]}"; do
        msg+=" ${e};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
