#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permission_user_bash_history"

# UID>=1000 olan user: name:home:shell
mapfile -t USERS < <(awk -F: '$3>=1000 {print $1":"$6":"$7}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No interactive users with UID>=1000 found"
    exit 0
fi

USERS_IGNORED_REGEX='nobody|nfsnobody'

bad=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user home shell <<< "$entry"

    # Ignored user-lər
    if grep -qP "$USERS_IGNORED_REGEX" <<< "$user"; then
        continue
    fi

    # Login shell yoxdursa, keç
    if [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/usr/sbin/nologin" ]; then
        continue
    fi

    hist="${home}/.bash_history"

    # Fayl yoxdursa, bu qayda üçün problem saymırıq
    [ -f "$hist" ] || continue

    # stat -c '%A' -> məsələn: -rw------- 
    perm=$(stat -Lc '%A' "$hist" 2>/dev/null || echo "")

    # Gözlənən pattern: -[rw-][w-]-------  (yəni user üçün r/w, x yoxdur; group/other boşdur)
    if ! [[ "$perm" =~ ^-[r-][w-]-------$ ]]; then
        bad+=("user=${user} file=${hist} perm=${perm}")
    fi
done

if [ "${#bad[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All existing .bash_history files have restrictive permissions (u=rw,go=)"
else
    msg="Some .bash_history files have too-permissive or wrong permissions:"
    for m in "${bad[@]}"; do
        msg+=" ${m};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
