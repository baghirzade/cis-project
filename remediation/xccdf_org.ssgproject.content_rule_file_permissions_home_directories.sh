#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_home_directories"

# UID >= 1000, UID != 65534, home != /
for home_dir in $(awk -F':' '{ if ($3 >= 1000 && $3 != 65534 && $6 != "/") print $6 }' /etc/passwd); do
    [ -d "$home_dir" ] || continue

    # Yalnız lazım olanda dəyiş (inode timestamp-ları boş yerə dəyişməmək üçün)
    find "$home_dir" -maxdepth 0 -perm /7027 -type d ! -lname '*' \
        -exec chmod u-s,g-w-s,o=- {} \;
done

exit 0
