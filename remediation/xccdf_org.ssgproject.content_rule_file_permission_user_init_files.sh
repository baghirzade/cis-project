#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permission_user_init_files"

var_user_initialization_files_regex='^\.[\w\- ]+$'

readarray -t interactive_users       < <(awk -F: '$3>=1000   {print $1}' /etc/passwd)
readarray -t interactive_users_home  < <(awk -F: '$3>=1000   {print $6}' /etc/passwd)
readarray -t interactive_users_shell < <(awk -F: '$3>=1000   {print $7}' /etc/passwd)

USERS_IGNORED_REGEX='nobody|nfsnobody'

for (( i=0; i<"${#interactive_users[@]}"; i++ )); do
    user="${interactive_users[$i]}"
    home="${interactive_users_home[$i]}"
    shell="${interactive_users_shell[$i]}"

    if grep -qP "$USERS_IGNORED_REGEX" <<< "$user"; then
        continue
    fi

    if [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/usr/sbin/nologin" ]; then
        continue
    fi

    [ -d "$home" ] || continue

    readarray -t init_files < <(
        find "$home" -maxdepth 1 -mindepth 1 -type f \
            -exec basename {} \; 2>/dev/null | grep -P "$var_user_initialization_files_regex" || true
    )

    for file in "${init_files[@]}"; do
        chmod u-s,g-wxs,o= "${home}/${file}" 2>/dev/null
    done
done

exit 0
