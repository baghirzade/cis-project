#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_cloud-init"
PATTERN_REGEX='.*cloud-init\.log([^\/]+)?$'
LOG_DIR="/var/log"

run() {

    files=$(find -P "$LOG_DIR" -maxdepth 1 -type f -regextype posix-extended -regex "$PATTERN_REGEX")

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|No cloud-init log files found"
        exit 0
    fi

    bad=0
    for f in $files; do
        mode=$(stat -c "%A" "$f")

        # Forbidden bits:
        # user: SUID
        # group: write, SUID, exec
        # others: write, exec, sticky
        if [[ "$mode" =~ s || "$mode" =~ ....[wx] || "$mode" =~ .......([wx]|t) ]]; then
            echo "WARN|$RULE_ID|Bad permissions on $f ($mode)"
            bad=1
        fi
    done

    if [[ $bad -eq 1 ]]; then
        exit 1
    fi

    echo "OK|$RULE_ID|All cloud-init log file permissions are correct"
    exit 0
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
