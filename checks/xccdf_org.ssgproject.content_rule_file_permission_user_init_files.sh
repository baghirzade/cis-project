#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permission_user_init_files"
USER_INIT_REGEX='^\.[\w\- ]+$'
USERS_IGNORED_REGEX='nobody|nfsnobody'

# UID>=1000 user-lər: name:home:shell
mapfile -t USERS < <(awk -F: '$3>=1000 {print $1":"$6":"$7}' /etc/passwd)

if [ "${#USERS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No interactive users with UID>=1000 found"
    exit 0
fi

bad=()

for entry in "${USERS[@]}"; do
    IFS=':' read -r user home shell <<< "$entry"

    # Ignore bəzi user-lər
    if grep -qP "$USERS_IGNORED_REGEX" <<< "$user"; then
        continue
    fi

    # Login shell olmayanları keç
    if [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/usr/sbin/nologin" ]; then
        continue
    fi

    [ -d "$home" ] || continue

    # Bu user-in init fayllarını tap
    mapfile -t init_files < <(
        find "$home" -maxdepth 1 -mindepth 1 -type f \
            -printf '%f\n' 2>/dev/null | grep -P "$USER_INIT_REGEX" || true
    )

    for fname in "${init_files[@]}"; do
        fpath="$home/$fname"
        [ -f "$fpath" ] || continue

        # stat -c '%A' -> məsələn: -rw-r----- 
        perm=$(stat -Lc '%A' "$fpath" 2>/dev/null || echo "")

        # İcazə qaydası:
        #  - birinci simvol: '-'
        #  - user üçün 3 simvol: istənilən
        #  - group üçün: r və ya '-' + sonra '--'
        #  - others: '---'
        #
        # regex: ^-.{3}[r-]---$
        if ! [[ "$perm" =~ ^-.{3}[r-]---$ ]]; then
            bad+=("user=${user} file=${fpath} perm=${perm}")
        fi
    done
done

if [ "${#bad[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All user init files (~/.*) have restrictive permissions (group max r, others none)"
else
    msg="Some user init files have too-permissive or incorrect permissions:"
    for m in "${bad[@]}"; do
        msg+=" ${m};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
