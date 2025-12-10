#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_accounts_root_path_dirs_no_write"

# Bu qayda root istifadəçisinin PATH dəyişənində olan direktoriyalar üçün keçərlidir
if [ "$(id -u)" -ne 0 ]; then
    echo "NOTAPPL|${RULE_ID}|Check must be run as root to validate root PATH"
    exit 0
fi

PATH_VALUE="${PATH:-}"

if [ -z "$PATH_VALUE" ]; then
    echo "WARN|${RULE_ID}|Root PATH is empty or undefined"
    exit 0
fi

IFS=':' read -r -a PATH_DIRS <<< "$PATH_VALUE"

bad_relative=()
bad_notdir=()
bad_owner=()
bad_perms=()

for dir in "${PATH_DIRS[@]}"; do
    # boş segmentləri keç (məs: PATH=:... və s.)
    [ -z "$dir" ] && continue

    # yalnız absolute path icazəlidir
    if [[ "$dir" != /* ]]; then
        bad_relative+=("$dir")
        continue
    fi

    if [ ! -d "$dir" ]; then
        bad_notdir+=("$dir")
        continue
    fi

    # owner və permission yoxla
    owner=$(stat -Lc '%U' "$dir" 2>/dev/null || echo "?")
    perms=$(stat -Lc '%A' "$dir" 2>/dev/null || echo "?")

    # root-a məxsus olmalıdır
    if [ "$owner" != "root" ]; then
        bad_owner+=("$dir($owner)")
    fi

    # group və ya others üçün yazma icazəsi olmamalıdır
    # -perm /022 -> group və ya others write varsa
    if find "$dir" -maxdepth 0 -perm /022 -type d ! -lname '*' >/dev/null 2>&1; then
        bad_perms+=("$dir($perms)")
    fi
done

if [ "${#bad_relative[@]}" -eq 0 ] && \
   [ "${#bad_notdir[@]}" -eq 0 ] && \
   [ "${#bad_owner[@]}" -eq 0 ] && \
   [ "${#bad_perms[@]}" -eq 0 ]; then

    echo "OK|${RULE_ID}|All directories in root PATH are absolute, exist, owned by root and not group/others writable"
else
    msg="Issues in root PATH directories:"
    if [ "${#bad_relative[@]}" -gt 0 ]; then
        msg+=" non-absolute entries: ${bad_relative[*]};"
    fi
    if [ "${#bad_notdir[@]}" -gt 0 ]; then
        msg+=" missing/not-directories: ${bad_notdir[*]};"
    fi
    if [ "${#bad_owner[@]}" -gt 0 ]; then
        msg+=" not owned by root: ${bad_owner[*]};"
    fi
    if [ "${#bad_perms[@]}" -gt 0 ]; then
        msg+=" group/others writable: ${bad_perms[*]};"
    fi
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
