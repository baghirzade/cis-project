#!/usr/bin/env bash

RULE_ID="xccdf_org.ssgproject.content_rule_set_ip6tables_default_rule"
TITLE="ip6tables must have DROP as default INPUT/OUTPUT/FORWARD policy"

run() {
    # ip6tables must exist
    if ! command -v ip6tables >/dev/null 2>&1; then
        echo "NOTAPPL|$RULE_ID|ip6tables command not available"
        return 0
    fi

    # Check INPUT chain
    INPUT_POLICY=$(ip6tables -S INPUT 2>/dev/null | grep "^-P" | awk '{print $3}')
    OUTPUT_POLICY=$(ip6tables -S OUTPUT 2>/dev/null | grep "^-P" | awk '{print $3}')
    FORWARD_POLICY=$(ip6tables -S FORWARD 2>/dev/null | grep "^-P" | awk '{print $3}')

    BAD=0

    if [ "$INPUT_POLICY" != "DROP" ]; then BAD=1; fi
    if [ "$OUTPUT_POLICY" != "DROP" ]; then BAD=1; fi
    if [ "$FORWARD_POLICY" != "DROP" ]; then BAD=1; fi

    if [ $BAD -eq 1 ]; then
        echo "WARN|$RULE_ID|One or more ip6tables default policies are not DROP"
        return 0
    fi

    echo "OK|$RULE_ID|All ip6tables default policies are DROP"
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    run
fi
