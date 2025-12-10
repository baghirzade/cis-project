#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_lastlog"
SEARCH_DIR="/var/log"
PATTERN_REGEX='.*lastlog(\.[^\/]+)?$'

run() {

    files=$(find -P "$SEARCH_DIR" -maxdepth 1 -type f \
        -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|No lastlog files found"
        exit 0
    fi

    bad=0
    for f in $files; do
        mode=$(stat -c "%A" "$f")

        #
        # Forbidden bits for this rule:
        # user: SUID
        # group: SUID
        # others: write, sticky, execute
        #
        if [[ "$mode" =~ s || "$mode" =~ .....s.* || "$mode" =~ .........[wxt] ]]; then
            echo "WARN|$RULE_ID|Invalid permissions on $f ($mode)"
            bad=1
        fi
    done

    if [[ $bad -eq 1 ]]; then
        exit 1
    fi

    echo "OK|$RULE_ID|All lastlog files comply with permission requirements"
    exit 0
}

# Run if script executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
