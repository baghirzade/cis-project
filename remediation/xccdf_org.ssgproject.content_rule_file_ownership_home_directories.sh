#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownership_home_directories"

# UID >= 1000 və UID != 65534 olan user:uid:home
awk -F: '$3 >= 1000 && $3 != 65534 {print $1":"$3":"$6}' /etc/passwd | \
while IFS=':' read -r user uid home; do
    # Home boşdursa, keç
    [ -n "$home" ] || continue

    # Home kataloqu mövcud deyilsə, bu qayda onu yaratmır (90-cı qayda bunu edir)
    [ -d "$home" ] || continue

    # Owner-i düzəlt
    chown -f --no-dereference "$uid" "$home" 2>/dev/null
done

exit 0
