#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_gdm3"
LOG_DIR="/var/log/gdm3"
PATTERN_REGEX='.*'

run() {

    files=$(find -P "$LOG_DIR" -type f -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|No gdm3 log files found"
        exit 0
    fi

    bad=0
    for f in $files; do
        mode=$(stat -c "%A" "$f")

        #
        # Forbidden permission bits:
        # user: SUID
        # group: SUID
        # others: write, exec, sticky
        #
        if [[ "$mode" =~ s || "$mode" =~ .....s.* || "$mode" =~ .........[wx,t] ]]; then
            echo "WARN|$RULE_ID|Bad permissions on $f ($mode)"
            bad=1
        fi
    done

    if [[ $bad -eq 1 ]]; then
        exit 1
    fi

    echo "OK|$RULE_ID|All gdm3 log file permissions are correct"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
