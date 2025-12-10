#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_groupownership_home_directories"

# UID >= 1000 və UID != 65534 olan user:gid:home
awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$4":"$6}' /etc/passwd | \
while IFS=':' read -r user gid home; do
    # Home boşdursa, keç
    [ -n "$home" ] || continue

    # Home kataloqu mövcud deyilsə, bu qayda onu yaratmır (90-cı qayda bunu edir)
    [ -d "$home" ] || continue

    # Qrup sahibini düzəlt
    chgrp -f --no-dereference "$gid" "$home" 2>/dev/null
done

exit 0
