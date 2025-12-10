#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_user_dot_user_ownership"

# UID >= 1000 və UID != 65534 olan istifadəçi + home
mapfile -t USERS < <(awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$3":"$6}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No regular users with UID>=1000 found"
    exit 0
fi

noncompliant_entries=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user uid home <<< "$entry"

    # Home kataloq mövcud deyilsə, keç
    if [ -z "$home" ] || [ ! -d "$home" ]; then
        continue
    fi

    # Home içində yalnız birinci səviyyədəki dotfile-lar
    while IFS= read -r file; do
        [ -e "$file" ] || continue

        file_uid=$(stat -c '%u' "$file" 2>/dev/null || echo "")
        if [ -n "$file_uid" ] && [ "$file_uid" != "$uid" ]; then
            noncompliant_entries+=("user=${user} file=${file} uid=${file_uid} expected_uid=${uid}")
        fi
    done < <(find -P "$home" -maxdepth 1 -type f -name ".[^.]*" 2>/dev/null)

done

if [ "${#noncompliant_entries[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All user dotfiles in home directories are owned by their respective users"
else
    msg="Some dotfiles are not owned by their respective users:"
    for e in "${noncompliant_entries[@]}"; do
        msg+=" ${e};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
