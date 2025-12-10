#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownership_home_directories"

# UID >= 1000 və UID != 65534 olan istifadəçilər: user:uid:home
mapfile -t USERS < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$3":"$6}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No regular users with UID>=1000 found"
    exit 0
fi

mismatches=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user uid home <<< "$entry"

    # Home boşdursa və ya mövcud deyilsə, bu qayda üçün keçirik
    [ -n "$home" ] || continue
    [ -d "$home" ] || continue

    # Home kataloqunun owner UID-ni oxu
    home_uid=$(stat -Lc '%u' "$home" 2>/dev/null || echo "")

    # stat uğursuzdursa, keç
    [ -n "$home_uid" ] || continue

    if [ "$home_uid" != "$uid" ]; then
        mismatches+=("user=${user} home=${home} expected_uid=${uid} actual_uid=${home_uid}")
    fi
done

if [ "${#mismatches[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All interactive users' home directories have correct user ownership"
else
    msg="Some home directories have incorrect user ownership:"
    for m in "${mismatches[@]}"; do
        msg+=" ${m};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
