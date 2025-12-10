#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_home_directories"

# UID >= 1000, UID != 65534, home != /
mapfile -t HOME_DIRS < <(
    awk -F':' '{ if ($3 >= 1000 && $3 != 65534 && $6 != "/") print $6 }' /etc/passwd
)

if [ "${#HOME_DIRS[@]}" -eq 0 ]; then
    echo "NOTAPPL|${RULE_ID}|No interactive users with valid home directories found"
    exit 0
fi

bad=()

for home_dir in "${HOME_DIRS[@]}"; do
    [ -d "$home_dir" ] || continue

    # -perm /7027 : hər hansı bu bitlərdən biri qoyulubsa:
    #   7xxx -> setuid, setgid, sticky
    #   x0x2 -> group write
    #   x0x7 -> others oxuma/yazma/icra
    #
    # Yəni: xüsusi bitlər, group write və others üçün hər hansı icazə varsa, bu dir problemli sayılır.
    if find "$home_dir" -maxdepth 0 -perm /7027 -type d ! -lname '*' >/dev/null 2>&1; then
        perm=$(stat -Lc '%A' "$home_dir" 2>/dev/null || echo '?')
        bad+=("${home_dir}(${perm})")
    fi
done

if [ "${#bad[@]}" -eq 0 ]; then
    echo "OK|${RULE_ID}|All user home directories have restrictive permissions (no SUID/SGID/sticky, no group write, no others perms)"
else
    msg="Some home directories have too-permissive or incorrect permissions:"
    for d in "${bad[@]}"; do
        msg+=" ${d};"
    done
    echo "WARN|${RULE_ID}|${msg}"
fi

exit 0
