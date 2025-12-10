#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_ownerships_var_log_sssd"

run() {

    # Find files not owned by root or sssd
    mapfile -t files < <(find -P /var/log/sssd/ -type f \
        ! -user root ! -user sssd \
        -regextype posix-extended -regex '.*' 2>/dev/null)

    # If no non-compliant files exist → OK
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|All /var/log/sssd files are owned by root or sssd"
        return 0
    fi

    # Convert list to a single-line message (required by SCAP)
    file_list=$(printf '%s ' "${files[@]}")

    echo "FAIL|$RULE_ID|Non-compliant files: $file_list"
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi