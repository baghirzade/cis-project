#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_gdm"

run() {

    # Find files under /var/log/gdm not owned by root
    mapfile -t files < <(find -P /var/log/gdm/ -type f ! -user 0 -regextype posix-extended -regex '.*' 2>/dev/null)

    if [[ ${#files[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|All /var/log/gdm files are owned by root"
        return 0
    fi

    # Join file list into a single message line (SCAP-compatible)
    file_list=$(printf '%s ' "${files[@]}")

    echo "FAIL|$RULE_ID|Non-root owned files: $file_list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi