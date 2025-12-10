#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownership_home_directories"

# UID >= 1000 və UID != 65534 olan istifadəçilər: user:gid:home
mapfile -t USERS < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$4":"$6}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No regular users with UID>=1000 found"
    exit 0
fi

mismatches=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user gid home <<< "$entry"

    # Home boşdursa və ya mövcud deyilsə, bu qayda üçün atlayırıq
    [ -n "$home" ] || continue
    [ -d "$home" ] || continue

    # Home kataloqunun qrup GID-ni oxu
    home_gid=$(stat -Lc '%g' "$home" 2>/dev/null || echo "")

    # stat uğursuzdursa, keç
    [ -n "$home_gid" ] || continue

    if [ "$home_gid" != "$gid" ]; then
        mismatches+=("user=${user} home=${home} expected_gid=${gid} actual_gid=${home_gid}")
    fi
done

if [ "${#mismatches[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All interactive users' home directories have correct group ownership"
else
    msg="Some home directories have incorrect group ownership:"
    for m in "${mismatches[@]}"; do
        msg+=" ${m};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
