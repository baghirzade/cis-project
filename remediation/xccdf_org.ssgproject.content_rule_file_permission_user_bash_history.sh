#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permission_user_bash_history"

readarray -t interactive_users       < <(awk -F: '$3>=1000 {print $1}' /etc/passwd)
readarray -t interactive_users_home  < <(awk -F: '$3>=1000 {print $6}' /etc/passwd)
readarray -t interactive_users_shell < <(awk -F: '$3>=1000 {print $7}' /etc/passwd)

USERS_IGNORED_REGEX='nobody|nfsnobody'

for (( i=0; i<${#interactive_users[@]}; i++ )); do
    user="${interactive_users[$i]}"
    home="${interactive_users_home[$i]}"
    shell="${interactive_users_shell[$i]}"

    # Ignore bəzi istifadəçilər
    if grep -qP "$USERS_IGNORED_REGEX" <<< "$user"; then
        continue
    fi

    # Login shell olmayanları keç
    if [ "$shell" = "/sbin/nologin" ] || [ "$shell" = "/usr/sbin/nologin" ]; then
        continue
    fi

    hist="${home}/.bash_history"

    # Fayl mövcud deyilsə, heç nə eləmirik
    [ -f "$hist" ] || continue

    chmod u-sx,go= "$hist" 2>/dev/null
done

exit 0
