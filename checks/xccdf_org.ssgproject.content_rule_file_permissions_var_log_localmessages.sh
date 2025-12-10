#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_localmessages"
SEARCH_DIR="/var/log"
PATTERN_REGEX='.*localmessages([^\/]+)?$'

run() {

    files=$(find -P "$SEARCH_DIR" -maxdepth 1 -type f \
        -regextype posix-extended -regex "$PATTERN_REGEX" 2>/dev/null)

    if [[ -z "$files" ]]; then
        echo "OK|$RULE_ID|No localmessages files found"
        exit 0
    fi

    bad=0
    for f in $files; do
        mode=$(stat -c "%A" "$f")

        #
        # Forbidden bits according to remediation command:
        #  user:   SUID
        #  group:  write, SUID, SGID
        #  other:  write, sticky, execute
        #
        if [[ "$mode" =~ s || "$mode" =~ .....[wsS].* || "$mode" =~ .........[wxt] ]]; then
            echo "WARN|$RULE_ID|Invalid permissions on $f ($mode)"
            bad=1
        fi
    done

    if [[ $bad -eq 1 ]]; then
        exit 1
    fi

    echo "OK|$RULE_ID|All localmessages files comply with permission requirements"
    exit 0
}

# Run when executed directly
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
