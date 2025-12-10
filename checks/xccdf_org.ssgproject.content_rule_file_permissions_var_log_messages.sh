#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_file_permissions_var_log_messages"
FILE="/var/log/messages"

run() {

    if [[ ! -f "$FILE" ]]; then
        echo "OK|$RULE_ID|File not found: $FILE"
        exit 0
    fi

    mode=$(stat -c "%A" "$FILE")

    #
    # Forbidden bits according to remediation:
    #   user:   SUID
    #   group:  write, SUID, SGID
    #   other:  write, read, execute, sticky
    #
    if [[ "$mode" =~ s || "$mode" =~ .....[wsS].* || "$mode" =~ .........[wrtx] ]]; then
        echo "WARN|$RULE_ID|Invalid permissions on $FILE ($mode)"
        exit 1
    fi

    echo "OK|$RULE_ID|Correct permissions on $FILE ($mode)"
    exit 0
}

# Run automatically if script is executed
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
