#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_gdm3"

run() {

    # Collect non-root owned files under /var/log/gdm3
    mapfile -t files < <(find -P /var/log/gdm3/ -type f \
        ! -user 0 \
        -regextype posix-extended -regex '.*' 2>/dev/null)

    # If nothing found → OK
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|All /var/log/gdm3 files are owned by root"
        return 0
    fi

    # Join list into a single line — SCAP requires single-line messages
    file_list=$(printf '%s ' "${files[@]}")

    echo "FAIL|$RULE_ID|Non-root owned files found: $file_list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi