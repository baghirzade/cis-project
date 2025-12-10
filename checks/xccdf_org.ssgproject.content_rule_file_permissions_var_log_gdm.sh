#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_gdm"
LOG_DIR="/var/log/gdm"
PATTERN_REGEX='.*'

run() {

    mapfile -t files < <(find -P "$LOG_DIR" -type f -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

    # If no files → OK
    if [[ ${#files[@]} -eq 0 ]]; then
        echo "OK|$RULE_ID|No gdm log files found"
        return 0
    fi

    # Gather all noncompliant files
    noncompliant=()

    for f in "${files[@]}"; do
        mode=$(stat -c "%A" "$f")

        # Forbidden:
        #  - user or group SUID
        #  - others write OR exec OR sticky
        if [[ "$mode" =~ s || "$mode" =~ .....s.* || "$mode" =~ .........[wx,t] ]]; then
            noncompliant+=("$f($mode)")
        fi
    done

    # If any violations exist → FAIL
    if [[ ${#noncompliant[@]} -gt 0 ]]; then
        list=$(printf "%s " "${noncompliant[@]}")
        echo "FAIL|$RULE_ID|Files with bad permissions: $list"
        return 1
    fi

    # Otherwise everything OK
    echo "OK|$RULE_ID|All gdm log files have correct permissions"
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi